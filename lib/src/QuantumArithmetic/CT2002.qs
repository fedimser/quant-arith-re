/// Implementation of addition and subtraction presented in paper:
///   Quantum full adder and subtractor,
///   Kai-Wen Cheng and Chien-Cheng Tseng, 2002.

import Std.Diagnostics.Fact;

// 1-bit quantum Full Adder.
operation QFA(carry_im1 : Qubit, a_i : Qubit, b_i : Qubit, carry_i : Qubit) : Unit is Adj + Ctl {
    CCNOT(a_i, b_i, carry_i);
    CNOT(a_i, b_i);
    CCNOT(carry_im1, b_i, carry_i);
    CNOT(carry_im1, b_i);
}

// Computes (a,b) = (a, a+b).
operation AddWithGarbage(a : Qubit[], b : Qubit[], carry : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes must match.");
    Fact(Length(carry) == n + 1, "Registers sizes must match.");
    for i in 0..n-1 {
        QFA(carry[i], a[i], b[i], carry[i + 1]);
    }
}

// Computes C ⊕= (A+B) % 2^n.
operation Add(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Registers sizes must match.");
    Fact(Length(C) == n, "Registers sizes must match.");
    use carry = Qubit[n + 1];
    within {
        AddWithGarbage(A, B, carry);
    } apply {
        for i in 0..n-1 {
            CNOT(B[i], C[i]);
        }
    }
}

// 1-bit quantum full subtractor.
operation QFS(borrow_im1 : Qubit, a_i : Qubit, b_i : Qubit, borrow_i : Qubit) : Unit is Adj + Ctl {
    CNOT(borrow_im1, b_i);
    X(a_i);
    CCNOT(a_i, b_i, borrow_i);
    CNOT(borrow_im1, b_i);
    CCNOT(borrow_im1, b_i, borrow_i);
    X(a_i);
    CNOT(a_i, b_i);
    CNOT(borrow_im1, b_i);
}

// Computes (a,b) = (a, a-b).
operation SubtractWithGarbage(a : Qubit[], b : Qubit[], brw : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes must match.");
    Fact(Length(brw) == n + 1, "Registers sizes must match.");
    for i in 0..n-1 {
        QFS(brw[i], a[i], b[i], brw[i + 1]);
    }
}

// Computes C ⊕= (A-B) % 2^n.
operation Subtract(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Registers sizes must match.");
    Fact(Length(C) == n, "Registers sizes must match.");
    use brw = Qubit[n + 1];
    within {
        SubtractWithGarbage(A, B, brw);
    } apply {
        for i in 0..n-1 {
            CNOT(B[i], C[i]);
        }
    }
}

export Add, Subtract;
