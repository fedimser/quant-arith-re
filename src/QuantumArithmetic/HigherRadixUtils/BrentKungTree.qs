// Used for generation of a Brent King tree which utilizes
// p and g groups to generate an initial state for a high
// radix quantum adder.

import Std.Math.Lg;
import Std.Math.Ceiling;
import Std.Math.Min;
import Std.Convert.IntAsDouble;
import Std.Arrays.Zipped;
import QuantumArithmetic.Utils;
import QuantumArithmetic.WBC2023.LogicalAND;
import QuantumArithmetic.WBC2023.UnpairedCCNOT;


/// Function to generate the Brent-Kung tree matrix
function BK_tree(num_qubits : Int) : Int[][] {
    let bitwidth_i = num_qubits -1;
    if (bitwidth_i == 0){
       return Repeated(Repeated(-1, 0), 0); 
    }
    let log2_bitwidth : Int = BitLength(bitwidth_i); //Ceiling(Lg(IntAsDouble(bitwidth_i)));

    mutable first_array : Int[] = Repeated(0, num_qubits);

    for i in 0..bitwidth_i {
        set first_array w/= i <- i;
    }

    // original implementation from paper used size of log2_bitdwidth*2
    // however that results in an incorrect BK Tree
    mutable tree_matrice = [first_array, size=bitwidth_i+1];

    for i_row in 0..log2_bitwidth-1 {
        let shift_length = 2^(i_row +1);
        let starting_index = shift_length - 2;
        let starting_value = 2^i_row -1;

       
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

        if bitwidth_i-1 - indexes_start >= 0 {

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

            // original paper implemenation used log2_bitwidth*2 instead of bitwidth_i
            // this resulted in an incorrect BK Tree
            let myrow : Int = bitwidth_i - i_row; 
            mutable row = tree_matrice[myrow];
            for (index, val) in Zipped(indexes, values) {
                set row w/= index+1 <- val;
            }
            set tree_matrice w/= myrow <- row;
        }
    }

    return tree_matrice;
}


/// This function finds the BK operations in the BK Tree.
/// A list of tuples is returned with the following set (row, column, value)
function get_BK_ops(BK_tree: Int[][]) : (Int, Int, Int)[] {
    mutable num_ops : Int = 0;
    for i in 0..Length(BK_tree)-1{
        for j in 0..Length(BK_tree[0])-1{
            if BK_tree[i][j] != j {
                set num_ops += 1;
            }
        }
    }

    mutable op_list = Repeated((0, 0, 0), num_ops);
    set num_ops = 0;
    for i in 0..Length(BK_tree)-1{
        for j in 0..Length(BK_tree[0])-1{
            if BK_tree[i][j] != j {
                set op_list w/= num_ops <- (i, j, BK_tree[i][j]);
                set num_ops += 1;
            }
        }
    }

    return op_list;
}

/// The CCNOT's use Method 3 from the paper for decomposition (UnpairedCCNOT)
operation simpleBKTree_Process(BK_operations: (Int, Int, Int)[], qubits_p: Qubit[], qubits_g: Qubit[], ancilla: Qubit[]) : Unit is Adj {
    for i in 0..Length(BK_operations)-1{
        let (row, col, val) = BK_operations[i];
        // calculate P
        UnpairedCCNOT(qubits_p[val], qubits_p[col], ancilla[i]);

        // calculate G
        UnpairedCCNOT(qubits_g[val], qubits_p[col], qubits_g[col]);

        // SWAP(qubits_p[col], ancilla[i]);
        Utils.SWAPViaRelabel(qubits_p[col], ancilla[i]);
    } 
}

/// Helper function to return the number of bits needed to represent an int
function BitLength(x: Int) : Int {
    mutable length = 0;
    mutable value = x;
    while (value > 0) {
        set length += 1;
        set value /= 2;
    }
    return length;
}