/// Implementation of the adder presented in paper:
///   A new quantum ripple-carry addition circuit
///   Cuccaro, Draper, Kutin, Moulton, 2004.
///   https://arxiv.org/pdf/quant-ph/0410184
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;

operation MAJ(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    CNOT(C, B);
    CNOT(C, A);
    CCNOT(A, B, C);
}

// UnMajority and Add (2-CNOT version).
operation UMA_v1(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    CCNOT(A, B, C);
    CNOT(C, A);
    CNOT(A, B);
}

// UnMajority and Add (3-CNOT version).
operation UMA_v2(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    X(B);
    CNOT(A, B);
    CCNOT(A, B, C);
    X(B);
    CNOT(C, A);
    CNOT(C, B);
}

// Simple (unoptimized) version of the adder, from §2.
// Computes B:=(A+B)%(2^n); Z⊕=(A+B)/(2^n).
operation Add_Simple(A : Qubit[], B : Qubit[], Z : Qubit) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    use C = Qubit();

    MAJ(C, B[0], A[0]);
    for i in 1..n-1 {
        MAJ(A[i-1], B[i], A[i]);
    }
    CNOT(A[n-1], Z);
    for i in n-1..-1..1 {
        UMA_v1(A[i-1], B[i], A[i]);
    }
    UMA_v1(C, B[0], A[0]);
}

// Optimized adder, from §3.
// Computes B:=(A+B)%(2^n); Z⊕=(A+B)/(2^n).
operation Add_Optimized(A : Qubit[], B : Qubit[], Z : Qubit) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(n >= 4, "n must be at least 4.");
    use C = Qubit();

    for i in 1..n-1 {
        CNOT(A[i], B[i]);
    }
    CNOT(A[1], C);
    CCNOT(A[0], B[0], C);
    CNOT(A[2], A[1]);
    CCNOT(C, B[1], A[1]);
    CNOT(A[3], A[2]);
    for i in 2..n-3 {
        CCNOT(A[i-1], B[i], A[i]);
        CNOT(A[i + 2], A[i + 1]);
    }
    CCNOT(A[n-3], B[n-2], A[n-2]);
    CNOT(A[n-1], Z);
    CCNOT(A[n-2], B[n-1], Z);
    for i in 1..n-2 {
        X(B[i]);
    }
    CNOT(C, B[1]);
    for i in 2..n-1 {
        CNOT(A[i-1], B[i]);
    }
    CCNOT(A[n-3], B[n-2], A[n-2]);
    for i in n-3..-1..2 {
        CCNOT(A[i-1], B[i], A[i]);
        CNOT(A[i + 2], A[i + 1]);
        X(B[i + 1]);
    }
    CCNOT(C, B[1], A[1]);
    CNOT(A[3], A[2]);
    X(B[2]);
    CCNOT(A[0], B[0], C);
    CNOT(A[2], A[1]);
    X(B[1]);
    CNOT(A[1], C);
    for i in 0..n-1 {
        CNOT(A[i], B[i]);
    }
}

// Computes B:=(A+B)%(2^n).
operation Add(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    if (n >= 5) {
        Add_Optimized(A[0..n-2], B[0..n-2], B[n-1]);
    } elif (n >= 2) {
        Add_Simple(A[0..n-2], B[0..n-2], B[n-1]);
    }
    CNOT(A[n-1], B[n-1]);
}

// Computes B:=(A+B)%(2^n), Z⊕=(A+B)/(2^n).
operation AddWithCarry(A : Qubit[], B : Qubit[], Z : Qubit) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    if (n >= 4) {
        Add_Optimized(A, B, Z);
    } elif (n >= 1) {
        Add_Simple(A, B, Z);
    }
}

// Computes B:=(A+B)%(2^n).
operation AddUnoptimized(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    if (n>=2) {
        Add_Simple(A[0..n-2], B[0..n-2], B[n-1]);
    }
    CNOT(A[n-1], B[n-1]);
}

export Add, AddUnoptimized, AddWithCarry;
