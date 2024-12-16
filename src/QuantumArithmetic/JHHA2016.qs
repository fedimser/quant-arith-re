/// Implementation of the multiplier presented in paper:
/// Ancilla-Input and Garbage-Output Optimized Design of a Reversible Quantum Integer Multiplier
/// Jayashree HV, Himanshu Thapliyal, Hamid R. Arabnia, V K Agrawal, 2016.
/// https://arxiv.org/abs/1608.01228

import Std.Diagnostics.Fact;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.HigherRadix;


// Computes P+=Am*B.
// Zcin must be prepared in zero state and is returned in zero state.
operation AddNop(P:Qubit[], B:Qubit[],  Zcin:Qubit, Am:Qubit) : Unit is Adj + Ctl {

}

// Rotates right bits of P.
operation RotateRight(P: Qubit[]): Unit is Adj+Ctl {
    let k: Int = Length(P);
    let k1: Int = k/2;
    for i in 0..k1-1 {
        SWAP(P[i], P[k-1-i]);
    }
    for i in 0..k1-2+(k%2) {
        SWAP(P[i], P[k-2-i]);
    }
}

// Computes P+=A*B.
operation Multiply(A: Qubit[], B: Qubit[], P: Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(Length(P) == 2* n, "Register sizes must match.");


}