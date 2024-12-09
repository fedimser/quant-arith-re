/// Implementation of the adder presented in paper:
///   A new quantum ripple-carry addition circuit
///   Cuccaro, Draper, Kutin, Moulton, 2004.
///   https://arxiv.org/pdf/quant-ph/0410184

import Std.Diagnostics.Fact;

operation MAJ(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    CNOT(C, B);
    CNOT(C, A);
    CCNOT(A, B, C);
}

// UnMajority and Add.
operation UMA_v1(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    CCNOT(A, B, C);
    CNOT(C, A);
    CNOT(A, B);
}

operation UMA_v2(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    X(B);
    CNOT(A, B);    
    CCNOT(A, B, C);
    X(B);
    CNOT(C, A);
    CNOT(C, B);
}

// Simple (unoptimized) version of the adder, from chapter 2 of the paper.
// Computes B += A (modulo 2^n).
// Numbers are little-endian.
operation Add_Simple(A : Qubit[], B : Qubit[]) : Unit // is Adj + Ctl 
{
    let n: Int = Length(A);
    Fact(Length(B) == n, "Registers sizes must match.");
    use C0 = Qubit();
    MAJ(C0, B[0], A[0]);
    for i in 1..n-1 {
        MAJ(A[i-1], B[i], A[i]);
    }
    for i in n-1..-1..1 {
        UMA_v1(A[i-1], B[i], A[i]);
    }
    UMA_v1(C0, B[0], A[0]);
}

// TODO: implement optimized version.

export Add_Simple;
