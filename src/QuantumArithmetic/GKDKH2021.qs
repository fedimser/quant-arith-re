/// Implementation of the adder and multiplier presented in paper:
///   T-Count Optimized Wallace Tree Integer Multiplier for Quantum Computing
///   S. S. Gayathri, R. Kumar, Samiappan Dhanalakshmi, Brajesh Kumar Kaushik, Majid Haghparast, 2021.
///   https://doi.org/10.1007/s10773-021-04864-3
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;

operation QuantumFullAdder(A : Qubit, B : Qubit, Sum : Qubit, Carry: Qubit) : Unit is Adj + Ctl {
    CNOT(Carry, A);
    CNOT(B, Sum);
    CNOT(A, Sum);
    CNOT(Carry, B);
    CCNOT(A, B, Carry);
    CNOT(Sum, B);
    CNOT(Sum, A);
}

/// Computes C=(A+B)%2^n.
/// WARNING: it swaps A and B as a result!
/// C must be prepared in zero state.
/// Carry may contain carry-in (or be zero); contains carry-out in the end.
operation Add(A: Qubit[], B: Qubit[], C: Qubit[], Carry: Qubit): Unit is Adj + Ctl  {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(C) == n, "Size mismatch.");
    for i in 0..n-1{
        QuantumFullAdder(A[i], B[i], C[i], Carry);
    }
}

/// Computes C=(A+B)%2^n. 
/// C must be prepared in zero state.
operation Add_Mod2N(A: Qubit[], B: Qubit[], C: Qubit[]): Unit is Adj {
    let n = Length(A);
    if (n>=2) {
        Add(A[0..n-2], B[0..n-2], C[0..n-2], C[n-1]);
    }
    // Undo swapping A and B.
    for i in 0..n-2 {
        Relabel([A[i], B[i]], [B[i], A[i]]);
    }
    // Compute high bit.
    CNOT(A[n-1], C[n-1]);
    CNOT(B[n-1], C[n-1]);
}

export Add, Add_Mod2N;
