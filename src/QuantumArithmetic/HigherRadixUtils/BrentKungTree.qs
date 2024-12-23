// Used for generation of a Brent King tree which utilizes
// p and g groups to generate an initial state for a high
// radix quantum adder.

import Std.Math.Lg;
import Std.Math.Ceiling;
import Std.Math.Min;
import Std.Convert.IntAsDouble;
import Std.Arrays.Zipped;

/// Function to generate the Brent-Kung tree matrix
function BK_tree(num_qubits : Int) : Int[][] {
    let bitwidth_i = num_qubits -1;
    let log2_bitwidth : Int = Ceiling(Lg(IntAsDouble(bitwidth_i)));
    mutable shift_length : Int = 0;
    mutable starting_index : Int = 0;
    mutable starting_value : Int = 0;

    mutable first_array : Int[] = Repeated(0, num_qubits);

    for i in 0..bitwidth_i {
        set first_array w/= i <- i;
    }
    mutable tree_matrice = [first_array, size=log2_bitwidth*2];

    for i_row in 0..log2_bitwidth-1 {
        set shift_length = 2^(i_row +1);
        set starting_index = shift_length - 2;
        set starting_value = 2^i_row -1;

       
        if bitwidth_i-starting_index != 0 {
            mutable values_seq : Int[] = Repeated(0, 1+ (bitwidth_i-1 - starting_value) / shift_length);
            mutable indexes_seq : Int[] = Repeated(0, 1+ (bitwidth_i-1 - starting_index) / shift_length);

            mutable temp_index: Int = 0;
            for i in starting_value..shift_length..bitwidth_i-1 {
                set values_seq w/= temp_index <- i;
                set temp_index = temp_index + 1;
            }

            set temp_index = 0;
            for i in starting_index..shift_length..bitwidth_i-1{
                set indexes_seq w/= temp_index <- i;
                set temp_index += 1;
            }

            // no continue so only perfrom the following where indexes_seq exists
            if (Length(indexes_seq) > 0){
                mutable row = tree_matrice[i_row];

                // for index, val in zip(indexes_seq, values_seq)
                for (index, val) in Zipped(indexes_seq, values_seq){
                    // let index = indexes_seq[i];
                    // let val = values_seq[i];
                    //tree_matrice[idx_row][index+1] = val
                    set row w/= index+1 <- val;
                }

                set tree_matrice w/= i_row <- row;
            }
        }
    }


    for i_row in 1..log2_bitwidth {
        let shift : Int = 2^i_row;
        let values_start : Int = shift - 1;
        let indexes_start : Int = (-4 + 3 * (2^i_row)) / 2;

        if bitwidth_i-1 - indexes_start > 0 {

            mutable values : Int[] = Repeated(0, 1+ (bitwidth_i-1 - values_start) / shift);
            mutable indexes : Int[] = Repeated(0, 1+ (bitwidth_i-1 - indexes_start) / shift);

            mutable temp_index : Int = 0;
            for i in values_start..shift..bitwidth_i-1{
                set values w/= temp_index <- i;
                set temp_index += 1;
            }

            set temp_index = 0;
            for i in indexes_start..shift..bitwidth_i-1{
                set indexes w/= temp_index <- i;
                set temp_index += 1;
            }

            let myrow : Int = log2_bitwidth * 2 - i_row; 
            mutable row = tree_matrice[myrow];
            for (index, val) in Zipped(indexes, values) {
                set row w/= index+1 <- val;
            }
            set tree_matrice w/= myrow <- row;
        }
    }

    return tree_matrice;
}

function columns_of_importance(BK_tree: Int[][], row: Int, col_length: Int) : Int[] {
    mutable counter : Int = 0;
    for column in 0..col_length -1 {
        if BK_tree[row][column] != column {
            set counter += 1;
        }
    }

    mutable col_of_impt : Int [] = Repeated(0, counter);
    set counter = 0;
    for column in 0..col_length -1 {
        if BK_tree[row][column] != column {
            set col_of_impt w/= counter <- column;
            set counter += 1;
        }
    }

    return col_of_impt;

}

//BKTree_process(BK_tree, p_pairs, g_pairs, bk_ancilla, ancilla_index, col_length, row);
// the ancilla_index is the NEXT FREE index
operation BKTree_process(BK_tree: Int[][], qubits_p: Qubit[], qubits_g: Qubit[], ancilla: Qubit[], ancilla_index: Int, col_length: Int, row: Int) : Unit is Adj + Ctl{
    mutable temp_row : Int = row;
    let columns_of_importance : Int[] = columns_of_importance(BK_tree, temp_row, col_length);
    within{
        if Length(columns_of_importance) > 0 {
            for col_idx in 0..Length(columns_of_importance)-1{
                CCNOT(qubits_p[BK_tree[temp_row][columns_of_importance[col_idx]]], qubits_p[columns_of_importance[col_idx]], ancilla[ancilla_index+col_idx]);
            }
        }
    } apply{
        if Length(columns_of_importance) > 0 {
            for column in columns_of_importance{
                    // (qubits_g[BK_tree[temp_row][index]], qubits_p[index], qubits_g[index])
                    CCNOT(qubits_g[BK_tree[temp_row][column]], qubits_p[column], qubits_g[column]);
            }
        }
        let temp_row = temp_row + 1;
        let temp_ancilla_index : Int = ancilla_index + Length(columns_of_importance);
        if temp_row < Length(BK_tree){
            BKTree_process(BK_tree, qubits_p, qubits_g, ancilla, temp_ancilla_index, col_length, temp_row);
        }
    }
}

function num_ancilla(BK_tree: Int[][]) : Int{
    mutable counter : Int = 0;
    let col_length : Int = Length(BK_tree[0]) -1;
    for row in 0..Length(BK_tree)-1 {
        for column in 0..col_length {
            if BK_tree[row][column] != column {
                set counter = counter + 1;
            }
        }
    }
    return counter;
}

//function generate_BrentKung_tree(p_pairs : Qubit[], g_pairs: Qubit[] ) : Unit is Adj + Ctl {
operation generate_BrentKung_tree(p_pairs : Qubit[], g_pairs: Qubit[] ) : Unit is Adj + Ctl {

    // generate a tree - lsb is removed in generation of p_pairs
    mutable BK_tree : Int[][] = BK_tree(Length(p_pairs));
    

    // use the tree to make the circuit
    let row_length = Length(BK_tree);
    if row_length != 0 {
        mutable row : Int = 0;
        mutable ancilla_index : Int = 0;
        let col_length = Length(BK_tree[0]);

        // figure out ancilla size and create ancilla Qubit[]
        // for temp_row in 0..row_length-1 {
        //     for temp_column in 0.. col_length-1 {
        //         if BK_tree[temp_row][temp_column] != temp_column {
        //             set ancilla_index = ancilla_index + 1;
        //         }
        //     }
        // }
        use bk_ancilla = Qubit[num_ancilla(BK_tree)];
        let ancilla_index = 0;

        // call recursive function with all the stuff
        BKTree_process(BK_tree, p_pairs, g_pairs, bk_ancilla, ancilla_index, col_length, row);

        Message("No way!");





    }
    


}