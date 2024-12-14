// Used for generation of a Brent King tree which utilizes
// p and g groups to generate an initial state for a high
// radix quantum adder.

import Std.Math.Lg;
import Std.Math.Ceiling;
import Std.Math.Min;
import Std.Convert.IntAsDouble;

operation BK_tree(num_qubits : Int) : Int[][] {
    let bitwidth_i = num_qubits -1;
    let log2_bitwidth : Int = Ceiling(Lg(IntAsDouble(bitwidth_i)));
    mutable shift_length : Int = 0;
    mutable starting_index : Int = 0;
    mutable starting_value : Int = 0;

    let first_array = [0..bitwidth_i];
    let tree_matrice = [first_array, size=log2_bitwidth*2];

    for i_row in 0..log2_bitwidth-1 {
        set shift_length = 2^(i_row +1);
        set starting_index = shift_length - 2;
        set starting_value = 2^i_row -1;

        let values_seq = [starting_value..shift_length..bitwidth_i-1];
        let indexes_seq = [starting_index..shift_length..bitwidth_i-1];
        
        // no continue so only perfrom the following where indexes_seq exists
        if (Length(indexes_seq) > 0){
            for i in 0..Min([Length(indexes_seq), Length(values_seq)])-1 {
                let temp = indexes_seq[i];
                //let temp = temp +1;
               // set tree_matrice = tree_matrice w/ i_row <- (tree_matrice[i_row] w/ temp <- values_seq[i]);
            }
        }
    }



    return [[0,0],[0,0]];
}

operation generate_BrentKung_tree(p_pairs : Qubit[], g_pairs: Qubit[] ) : Unit is Adj + Ctl {
    let n = Length(p_pairs)-1;

    // generate a tree

    // use the tree to make the circuit


}