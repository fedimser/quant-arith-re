import QuantumArithmetic.WBC2023_new.BrentKung;
import Std.Diagnostics.DumpMachine;
// this is the main file to handle higher radix used in
// the file WBC2023.qs

import QuantumArithmetic.HigherRadixUtils.BrentKungTree;
import QuantumArithmetic.WBC2023.ApplyAndAssuming0Target;
import Std.Diagnostics.DumpRegister;


operation computeCarryHigherRadix(A: Qubit[], B: Qubit[], carry_bits: Qubit[], radix: Int, num_groups: Int) : Unit is Adj + Ctl {

    // designate ancillas
    use ancilla = Qubit[num_groups*radix];
    use group_ancilla = Qubit[num_groups];

    let BK_Tree : Int[][] = BrentKungTree.BK_tree(Length(group_ancilla));
    let BK_operations = BrentKungTree.get_BK_ops(BK_Tree);
    use bk_ancilla = Qubit[Length(BK_operations)];

    within {

        calculate_g(A[...radix*num_groups-1], B[...radix*num_groups-1], ancilla);
        calculate_p(A[...radix*num_groups-1], B[...radix*num_groups-1]);

        // p is now stored in B and g is now stored in the ancilla
        calculate_p_groups(B, group_ancilla, radix);
        calculate_g_groups(B, ancilla, radix, num_groups);
        
        // use BK Tree to generate carry bits 
        BrentKungTree.simpleBKTree_Process(BK_operations, group_ancilla, ancilla[radix-1..radix..Length(group_ancilla)*radix-1], bk_ancilla);

    } apply {
        // copy values out to carry_bits
        copy_carry_bits(ancilla[radix-1..radix...], carry_bits);
    }

}

operation calculate_g(A: Qubit[], B: Qubit[], ancilla: Qubit[]) : Unit is Adj + Ctl {
    for i in 0..Length(A)-1 {
        CCNOT(A[i], B[i], ancilla[i]);
    }
}

operation calculate_p(A: Qubit[], B: Qubit[]) : Unit is Adj + Ctl {
    for i in 0..Length(A)-1 {
        CNOT(A[i], B[i]);
    } 
}

operation calculate_p_groups(p: Qubit[], ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    for i in 0..Length(ancilla)-1{
        Controlled X(p[i*radix..(i+1)*radix-1], ancilla[i]);
    }
}

operation calculate_g_groups(p: Qubit[], g: Qubit[], radix: Int, num_groups: Int) : Unit is Adj + Ctl {
    for i in 0..num_groups-1{
        for j in 0..radix-2{
            CCNOT(g[i*radix+j], p[i*radix+j+1], g[i*radix+j+1]);
        }
    }
}

operation copy_carry_bits(ancilla: Qubit[], carry_bits: Qubit[]) : Unit is Adj + Ctl {
    for i in 0..Length(ancilla)-1{
        CNOT(ancilla[i], carry_bits[i]);
    }
}




// generate p groups which gets uncomputed
operation generate_p_groups(p: Qubit[], g: Qubit[], ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let n : Int = Length(ancilla);
    for i in 0..n-1{
        Controlled X(p[i*radix..(i+1)*radix-1], ancilla[i]);
    }
}