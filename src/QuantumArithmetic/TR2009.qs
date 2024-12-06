/// Implementation of the subtractor presented in paper:
///   Design of Efficient Reversible Binary Subtractors Based on A New Reversible Gate,
///   Himanshu Thapliyal and Nagarajan Ranganathan, 2009.
///   http://dx.doi.org/10.1109/ISVLSI.2009.49

import Std.Diagnostics.Fact;

// The "TR" gate from the paper.
// Computes: (A, B, C) := (A, A⊕B, C⊕(A*!B)).
operation TR(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    X(B);
    CCNOT(A, B, C);
    X(B);
    CNOT(A, B);
}

// Reversible Half Subtractor.
// A, B are inputs. Z must be initialized to 0.
// Computes: (A, B, Z) := (A⊕B, B, !A*B) = (Diff, B, Borr).
operation RHS(A : Qubit, B : Qubit, Z : Qubit) : Unit is Adj + Ctl {
    TR(B, A, Z);
}

// Reversible Full Subtractor.
// A, B, C are inputs. Z must be initialized to 0.
// Computes: (A, B, C, Z) := (Diff, B, C, Borr).
operation RFS(A : Qubit, B : Qubit, C : Qubit, Z : Qubit) : Unit is Adj + Ctl {
    TR(B, A, Z);
    TR(C, A, Z);
}

// Computes (B, A) := (B, A-B).
// Z must be prepared in zero state, and is left in some "garbage" state.
// Numbers are little-endian.
// Computation is modulo 2^n, where n is the size of registers.
operation SubtractWithGarbage(B : Qubit[], A : Qubit[], Z : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Registers sizes must match.");
    Fact(Length(Z) == n, "Registers sizes must match.");
    RHS(A[0], B[0], Z[0]);
    for i in 1..n-1 {
        let prev_borr = Z[i-1];
        RFS(A[i], B[i], prev_borr, Z[i]);
    }
}

// Computes C ⊕= (A-B) % 2^n.
// Doesn't change A and B.
// Numbers are little-endian.
operation Subtract(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Registers sizes must match.");
    Fact(Length(C) == n, "Registers sizes must match.");
    use Z = Qubit[n];
    within {
        SubtractWithGarbage(B, A, Z);
    } apply {
        for i in 0..n-1 {
            CNOT(A[i], C[i]);
        }
    }
}

export Subtract;
