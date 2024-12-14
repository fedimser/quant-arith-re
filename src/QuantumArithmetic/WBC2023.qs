/// Implementation of the adder presented in paper:
/// A Higher radix architecture for quantum carry-lookahead adder
/// Wang, Baksi, Chattopadhyay, 2024.
/// https://www.nature.com/articles/s41598-023-41122-4

import Std.Diagnostics.Fact;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.HigherRadix;


operation Add(A: Qubit[], B: Qubit[], radix: Int) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    use ancilla = Qubit[n];

    // call higher radix function that returns an initial state 
    HigherRadix(A, B, ancilla, radix);

    // call the adder which uses chunks to sum the numbers using the radix

}