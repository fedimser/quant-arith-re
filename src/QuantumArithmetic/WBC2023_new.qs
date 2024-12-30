import Std.Diagnostics.DumpMachine;
/// Implementation of the adder presented in paper:
/// A Higher radix architecture for quantum carry-lookahead adder
/// Wang, Baksi, Chattopadhyay, 2024.
/// https://www.nature.com/articles/s41598-023-41122-4

import Std.Diagnostics.Fact;
import Std.Diagnostics.DumpRegister;
import Std.Math.Floor;
import QuantumArithmetic.SC2023.PropagateP;
import QuantumArithmetic.SC2023.BKTree;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.generate_p_groups;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.generate_g_groups_pt1;

// Main Add function that takes A, B, and the radix
// The first step is setup the higher radix
// Then the Gidney RCA is used
operation Add(A: Qubit[], B: Qubit[], g: Qubit[], radix: Int) : Unit is Adj {
    DumpRegister(A);
    DumpRegister(B);
    let n : Int = Length(A);
    let num_groups : Int = n/radix;
    // use g = Qubit[n];
    mutable g_new = g[0..radix..n-1];
    use p_new = Qubit[num_groups];
    let BKOps = BKTree(num_groups-1);  //don't need the c_highest_bit
    Message($"BKOps: {BKOps}");
    use BKAccilla = Qubit[3 * Length(BKOps)];
    for i in 0..num_groups-1 {
        for j in 0..radix-2 {
            CCNOT(A[i*radix + j], B[i*radix + j], g[i*radix + j]);
        }
    }
    within{
        for i in 1..num_groups {
            CCNOT(A[i*radix-1], B[i*radix-1], g[i*radix-1]);
        }
        for i in 0..n-1 {
            CNOT(A[i], B[i]);
        }
        DumpRegister(B);
        DumpRegister(g);
        generate_p_groups(B, g, p_new, radix);
        DumpRegister(p_new);
        generate_g_groups_pt1(B, g, radix);
        DumpRegister(g_new);
        // include decomputation
        BrentKung(g_new, p_new, BKAccilla, BKOps);
    } apply {

    }
    //DEBUG
    Message("After higher radix before addition:");
    DumpRegister(B);
    DumpRegister(A);
    DumpRegister(g_new);
    use c0 = Qubit();
    let c_pair = g_new[1..num_groups-1] + [c0];
    DumpRegister(c_pair);

    // the rest of the groups include the carry
    for i in 0..num_groups-1 {
        CarryRipple4TAdder(A[i*radix..(i+1)*radix-1], B[i*radix..(i+1)*radix-1], c_pair[i]);
        DumpRegister(B[i*radix..(i+1)*radix-1]);
    }
    
    Message("final state:");

    // uncompute g_new
    // for i in 0..num_groups-1 {
    //     for j in 0..radix-2 {
    //         CCNOT(A[i*radix + j], B[i*radix + j], g[i*radix + j]);
    //     }
    // }
    // 00100 00000 00000
    // 100100000000000
    // 00100 00000 00000

}

operation PropagateG(gi: Qubit, pii: Qubit, giii: Qubit, acilla0: Qubit, acilla1: Qubit) : Unit is Adj + Ctl {
    // Calculate px_gy and new_p using Toffoli gate
    CCNOT(giii, pii, acilla0);
}

operation BrentKung(gNumber : Qubit[], pNumber : Qubit[], acillas : Qubit[], BKOps: (Int, Int, Int)[])  : Unit is Adj + Ctl {
    body...{
        let num_ops = Length(BKOps);
        for i in 0..num_ops - 1 {
            let (_, index_now, index_bk) = BKOps[i];
            let acillaOffset = 3 * i;

            // Use PropagateP for P propagation
            PropagateP(
                pNumber[index_now],
                pNumber[index_bk],
                acillas[acillaOffset + 2]
            );
            SWAP(pNumber[index_now], acillas[acillaOffset + 2]);

            // Use PropagateG for G propagation
            PropagateG(
                gNumber[index_now],
                pNumber[index_now],
                gNumber[index_bk],
                acillas[acillaOffset + 0],
                acillas[acillaOffset + 1]
            );
            SWAP(gNumber[index_now], acillas[acillaOffset + 1]);
        }
    }
    adjoint...{
        let num_ops = Length(BKOps);
        if (num_ops != 0) {
            
        for i in num_ops - 1..0 {
            let (_, index_now, index_bk) = BKOps[i];
            let acillaOffset = 3 * i;
            // Use PropagateP for P propagation
            SWAP(pNumber[index_now], acillas[acillaOffset + 2]);
            PropagateP(
                pNumber[index_now],
                pNumber[index_bk],
                acillas[acillaOffset + 2]
            );
        }
        }
    }
}

// TODO adapt to little endian
operation CarryRipple4TAdder(A : Qubit[], B : Qubit[], C0 : Qubit) : Unit is Adj + Ctl {
    let nrQubits = Length(A);
    DumpRegister(A);
    DumpRegister(B);
    DumpRegister([C0]);
    use T = Qubit[nrQubits - 1];

    for rippleI in 0 .. nrQubits - 2 {
        let carryInIdx = rippleI - 1;
        let littleEndianIdx = nrQubits - 1 - rippleI;
        if (carryInIdx == -1) {
            CNOT(C0, A[littleEndianIdx]);
            CNOT(C0, B[littleEndianIdx]);
        } else {
            CNOT(T[carryInIdx], A[littleEndianIdx]);
            CNOT(T[carryInIdx], B[littleEndianIdx]);
        }

        // Toffoli gate
        CCNOT(A[littleEndianIdx], B[littleEndianIdx], T[rippleI]);

        if (carryInIdx == -1) {
            CNOT(C0, T[rippleI]);
        } else {
            CNOT(T[carryInIdx], T[rippleI]);
        }
    }

    // Middle CNOT
    CNOT(T[nrQubits - 2], B[0]);

    // Propagate back the carry ripple
    for rippleI in nrQubits-2..-1..0 {
        let carryInIdx = rippleI - 1;
        let littleEndianIdx = nrQubits - 1 - rippleI;
        if (rippleI == 0) {
            CNOT(C0, T[rippleI]);
        } else {
            CNOT(T[carryInIdx], T[rippleI]);
        }

        // Toffoli gate
        CCNOT(A[littleEndianIdx], B[littleEndianIdx], T[rippleI]);

        // Reverse CNOTs
        if (rippleI != 0) {
            CNOT(T[carryInIdx], A[littleEndianIdx]);
        } else {
            CNOT(C0, A[littleEndianIdx]);
        }
    }

    // Compute the sums
    for sumI in 0 .. nrQubits - 1 {
        CNOT(A[sumI], B[sumI]);
    }
}
