/// Implementation of the adder presented in paper:
/// Improved quantum ripple-carry addition circuit
/// Feng WANG, Mingxing LUO, Huiran LI, Zhiguo QU, Xiaojun WANG, 2016.
/// https://link.springer.com/article/10.1007/s11432-015-5411-x
import Std.Diagnostics.Fact;

/// Computes (s, carry) := ((a+b+carry)%2, (a+b+carry)/2).
/// `s` must be prepared in zero state.
/// Figure 1 in the paper.
operation Adder(s : Qubit, b : Qubit, carry : Qubit, a : Qubit) : Unit is Adj {
    CNOT(b, s);
    CNOT(a, carry);
    CNOT(a, b);
    CCNOT(b, carry, a);
    CNOT(s, carry);
    CNOT(s, b);
    Relabel([b, a, s, carry], [s, b, carry, a]);
}

/// Computes S:=(A+B)%(2^n).
/// S must be prepared in zero state.
/// carry is both carry-in and carry-out.
operation AddWithCarry(A : Qubit[], B : Qubit[], S : Qubit[], carry : Qubit) : Unit is Adj {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(S) == n, "Size mismatch.");
    for i in 0..n-1 {
        Adder(S[i], B[i], carry, A[i]);
    }
}

/// Computes S:=(A+B)%(2^n).
/// S must be prepared in zero state.
operation AddMod2N(A : Qubit[], B : Qubit[], S : Qubit[]) : Unit is Adj {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(S) == n, "Size mismatch.");
    AddWithCarry(A[0..n-2], B[0..n-2], S[0..n-2], S[n-1]);
    CNOT(A[n-1], S[n-1]);
    CNOT(B[n-1], S[n-1]);
}

export AddWithCarry, AddMod2N;