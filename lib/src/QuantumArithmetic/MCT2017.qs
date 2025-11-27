/// Implementation of the multiplier presented in paper:
///   T-count Optimized Design of Quantum Integer Multiplication
///   Edgard Muñoz-Coreas, Himanshu Thapliyal, 2017.
///   https://arxiv.org/pdf/1706.05113
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;

/// Controlled addition, described in section III of the paper.
operation CtrlAdd(Ctrl : Qubit, A : Qubit[], B : Qubit[], Z0 : Qubit, Z1 : Qubit) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");

    // Step 1.
    for i in 1..n-1 {
        CNOT(A[i], B[i]);
    }
    // Step 2.
    CCNOT(Ctrl, A[n-1], Z0);
    for i in n-2..-1..1 {
        CNOT(A[i], A[i + 1]);
    }
    // Step 3.
    for i in 0..n-2 {
        CCNOT(B[i], A[i], A[i + 1]);
    }
    // Step 4.
    CCNOT(B[n-1], A[n-1], Z1);
    CCNOT(Ctrl, Z1, Z0);
    CCNOT(B[n-1], A[n-1], Z1);
    CCNOT(Ctrl, A[n-1], B[n-1]);
    // Step 5.
    for i in n-2..-1..0 {
        CCNOT(B[i], A[i], A[i + 1]);
        CCNOT(Ctrl, A[i], B[i]);
    }
    // Step 6.
    for i in 1..n-2 {
        CNOT(A[i], A[i + 1]);
    }
    // Step 7.
    for i in 1..n-1 {
        CNOT(A[i], B[i]);
    }
}

/// Computes C:=A*B.
/// Supports inputs of different sizes.
operation Multiply(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n1 = Length(A);
    let n2 = Length(B);
    Fact(Length(C) == n1 + n2, "Size mismatch.");
    use Ancilla = Qubit();
    let P = C + [Ancilla];

    // Step 1.
    for i in 0..n1-1 {
        CCNOT(B[0], A[i], P[i]);
    }
    // Steps 2-3.
    for i in 1..n2-1 {
        CtrlAdd(B[i], A, P[i..i + n1-1], P[i + n1], P[i + n1 + 1]);
    }
}


export Multiply;
