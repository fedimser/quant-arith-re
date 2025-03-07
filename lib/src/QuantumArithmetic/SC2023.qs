// Quantum Adder adapted from Ling Structure
// https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=10321948&tag=1
// modification to the original paper includes: precalculate the BK tree to allocate proper number of ancilla qubits,
// use SWAP instead of re-assigment for easier adjoint operation
import Std.ResourceEstimation.AuxQubitCount;
import Std.Diagnostics.Fact;
open Microsoft.Quantum.Intrinsic;
open Microsoft.Quantum.Arrays;

// T_n = sum 2^(n+1) a_n b_n, 1 bit left shift

// P_n = sum 2^n a_n \oplus b_n, difference between a and b

// Ln = extraction between T_n and P_n

// put all 1's in P_n to T_n

// Computes C ⊕= (A+B) % 2^n.
operation Add(A : Qubit[], B : Qubit[], pl: Qubit[], Z: Qubit) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Registers sizes must match.");

    // pre-calculation 
    use gl = Qubit[n];
    use p_1 = Qubit[n - 2]; // p_0 = p_1 = pl_0/0
    use g_1 = Qubit[n - 1]; // g_0 = gl_0

    // propagate g and p
    mutable p = [pl[0], pl[0]] + p_1;
    mutable g = [gl[0]] + g_1;

    // BK operations
    mutable indexBK1: Range = 0..2..n - 1;
    mutable indexBK2: Range = 1..2..n - 1;
    mutable gBK1 = g[indexBK1];
    mutable pBK1 = p[indexBK1];
    mutable gBK2 = g[indexBK2];
    mutable pBK2 = p[indexBK2];

    let bitNum1 = Length(gBK1);
    let BKOps1 = BKTree(bitNum1);

    let bitNum2 = Length(gBK2);
    let BKOps2 = BKTree(bitNum2);

    use accilla1 = Qubit[3 * Length(BKOps1)];
    use accilla2 = Qubit[3 * Length(BKOps2)];
    // step 1 needs special uncomputation
    for i in 0..n-1 {
        Step1(A[i], B[i], gl[i], pl[i]);
    }

    within{
        // step 2
        // do even first
        if (n % 2 == 0) {
            for i in 0..2..n-4 {
                Step2(pl[i], pl[i+1], gl[i], gl[i+1], p[i+2], g[i+1]);
            }
            ORGate(gl[n-2], gl[n-1], g[n-1]);
            for i in 1..2..n-3 {
                Step2(pl[i], pl[i+1], gl[i], gl[i+1], p[i+2], g[i+1]);
            }
        } else {
            for i in 0..2..n-3 {
                Step2(pl[i], pl[i+1], gl[i], gl[i+1], p[i+2], g[i+1]);
            }
            for i in 1..2..n-4 {
                Step2(pl[i], pl[i+1], gl[i], gl[i+1], p[i+2], g[i+1]);
            }
            ORGate(gl[n-2], gl[n-1], g[n-1]);
        }

        if (Length(BKOps1) > 0) {
            // LingBrentKung(g, p, accilla);
            BrentKung(gBK1, pBK1, accilla1, BKOps1);
        } 
        if (Length(BKOps2) > 0) {
            BrentKung(gBK2, pBK2, accilla2, BKOps2);
        }

    } apply {
        Summation(g, pl, B, Z);
    }
    // uncompute step 1
    for i in 0..n-1 {
        Step1_uncompute(A[i], B[i], gl[i], pl[i]);
    }

}

// step 1: 
// Toffoli with a and b as control, gl as target
// 3 CNOTs with a, b, gl as control, pl as target
// CNOT with a as control, b as target
operation Step1(a : Qubit, b : Qubit, gl : Qubit, pl : Qubit) : Unit is Adj + Ctl {
    CCNOT(a, b, gl);
    CNOT(a, pl);
    CNOT(b, pl);
    CNOT(gl, pl);
    CNOT(a, b);
}

// step 2:
// g = gl_i + gl_i-1, g_0 = gl_0
// p = pl_i * pl_i-1, p_0 = p_1 = 0
// Define a custom OR gate using Toffoli gates
operation ORGate(control1: Qubit, control2: Qubit, target: Qubit) : Unit is Adj + Ctl {
        X(control1);
        X(control2);
        CCNOT(control1, control2, target);
        X(control1);
        X(control2);
        X(target);
}

// Define Step2 operation for intermediate propagation variables
operation Step2(pl_i: Qubit, pl_i1: Qubit, gl_i: Qubit, gl_i1: Qubit, p_i: Qubit, g_i: Qubit) : Unit is Adj + Ctl {
        // Calculate pi using Toffoli gate
        CCNOT(pl_i, pl_i1, p_i);
        // Calculate gi using OR gate
        ORGate(gl_i, gl_i1, g_i);
}



// step 3:
// (g_x, p_x-1) O (g_y, p_y-1) = (g_x + p_x-1 * g_y, p_x-1 * p_y-1)
// H_i = g_i + p_i-1 * g_i-2, H_0 = g_0
function BitLength(x: Int) : Int {
    mutable length = 0;
    mutable value = x;
    while (value > 0) {
        set length += 1;
        set value /= 2;
    }
    return length;
}

operation PropagateG(gi: Qubit, pii: Qubit, giii: Qubit, acilla0: Qubit, acilla1: Qubit) : Unit is Adj + Ctl {
    // Calculate px_gy and new_p using Toffoli gate
    CCNOT(giii, pii, acilla0);
    ORGate(gi, acilla0, acilla1);
}

operation PropagateP(px: Qubit, py: Qubit, acilla2: Qubit) : Unit is Adj + Ctl {
    // Calculate px_gy and new_p using Toffoli gate
    CCNOT(py, px, acilla2);
}

/// Function to generate the Brent-Kung tree matrix
function BKTree(bitWidth : Int) : (Int, Int, Int)[] {
    let bitwidth_i = bitWidth - 1;
    mutable matrix = Repeated(Repeated(-1, bitwidth_i), bitwidth_i);
    let log2BitWidth = BitLength(bitwidth_i);
    mutable nitems = 0;
    for idxRow in 0 .. log2BitWidth - 1 {
        mutable row = matrix[idxRow];
        let shiftLength = 2 <<< idxRow;
        let startingIndex = shiftLength - 2;
        let startingValue = (1 <<< idxRow) - 1;
        let numIndexes = (bitwidth_i - startingIndex) / shiftLength;

        for i in 0 .. numIndexes {
            let idx = startingIndex + i * shiftLength;
            let val = startingValue + i * shiftLength;
            if idx < bitwidth_i {
                set row w/= idx <- val;
                set nitems += 1;
            }
        }
        set matrix w/= idxRow <- row;
    }
    for idxRow in 1 .. log2BitWidth {
        mutable row = matrix[bitwidth_i - idxRow];
        let shift = 1 <<< idxRow;
        let valuesStart = shift - 1;
        let indexesStart = (-4 + 3 * shift) / 2;
        let numIndexes = (bitwidth_i - valuesStart) / shift;
        for i in 0 .. numIndexes {
            let idx = indexesStart + i * shift;
            let val = valuesStart + i * shift;
            if idx < bitwidth_i {
                set row w/= idx <- val;
                set nitems += 1;
            }
        }
        set matrix w/= bitwidth_i - idxRow <- row;
    }
    // create a list of tuple of nitems
    mutable list = Repeated((0, 0, 0), nitems);
    set nitems = 0;
    for i in 0 .. bitwidth_i - 1 {
        for j in 0 .. bitwidth_i - 1 {
            if matrix[i][j] != -1 {
                set list w/= nitems <- (i, j + 1, matrix[i][j]);
                set nitems += 1;
            }
        }
    }
    return list;
}

operation BrentKung(gNumber : Qubit[], pNumber : Qubit[], acillas : Qubit[], BKOps: (Int, Int, Int)[])  : Unit is Adj + Ctl {

    let num_ops = Length(BKOps);
    for i in 0..num_ops - 1 {
        let (_, index_now, index_bk) = BKOps[i];
        let acillaOffset = 3 * i;
        // Use PropagateG for G propagation
        PropagateG(
            gNumber[index_now],
            pNumber[index_now],
            gNumber[index_bk],
            acillas[acillaOffset + 0],
            acillas[acillaOffset + 1]
        );
        // set gNumber[index_now] = acillas[acillaOffset + 1];
        SWAP(gNumber[index_now], acillas[acillaOffset + 1]);
        // Use PropagateP for P propagation
            PropagateP(
                pNumber[index_now],
                pNumber[index_bk],
                acillas[acillaOffset + 2]
            );
            SWAP(pNumber[index_now], acillas[acillaOffset + 2]);
    }

}

operation Summation(h: Qubit[], p: Qubit[], d: Qubit[], Z: Qubit) : Unit is Adj + Ctl {
    let n = Length(h);
    Fact(Length(p) == n, "The length of p must match the bit width.");
    Fact(Length(d) == n, "The length of d must match the bit width.");

    for i in 0..n-2 {
        CCNOT(h[i], p[i], d[i+1]);
    }
    CCNOT(h[n-1], p[n-1], Z);
}


operation Step1_uncompute(a : Qubit, b : Qubit, gl : Qubit, pl : Qubit) : Unit is Adj + Ctl {
    CNOT(gl, pl);
    CNOT(a, pl);
    CCNOT(a, pl, gl);
}


// Computes C ⊕= (A+B) % 2^n.
operation Add_Mod2N(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj {
    let n = Length(A);
    Fact(n >= 3, "n too small.");
    Add(A[0..n-2], B[0..n-2], C[0..n-2], C[n-1]);
    for i in 0..n-2 {
        Relabel([B[i], C[i]], [C[i], B[i]]);
    }
    CNOT(A[n-1], C[n-1]);
    CNOT(B[n-1], C[n-1]);
}