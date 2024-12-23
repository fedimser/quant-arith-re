/// Implementation of the adder presented in paper:
/// A Higher radix architecture for quantum carry-lookahead adder
/// Wang, Baksi, Chattopadhyay, 2024.
/// https://www.nature.com/articles/s41598-023-41122-4

import Std.Diagnostics.Fact;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.HigherRadix;
import QuantumArithmetic.AdditionStd.Add_CG;


operation Add(A: Qubit[], B: Qubit[], radix: Int) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    use ancilla = Qubit[n];

    // call higher radix function that returns an initial state 
    HigherRadix(A, B, ancilla, radix);

    // call the adder which uses chunks to sum the numbers using the radix
    for i in 0..n/radix-1 {
        let a_piece : Qubit[] = A[i*radix..(i+1)*radix -1];
        let b_piece : Qubit[] = B[i*radix..(i+1)*radix -1];
        Add_CG(a_piece, b_piece);
    }


}