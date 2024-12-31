/// Implementation of incrementer presented in paper:
///   A CLASS OF EFFICIENT QUANTUM INCREMENTER GATES FOR QUANTUM CIRCUIT SYNTHESIS
///   Xiaoyu Li, Guowu Yang, Carlos Manuel Torres Jr., Desheng Zheng, Kang L. Wang, 2013.
///   https://doi.org/10.1142/S0217979213501919

/// Computes A := (A+1)%(2^n).
/// Doesn't allocate ancillas, but uses expensive multi-controlled gates.
operation Increment_v1(A : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    for i in n-1..-1..0 {
        Controlled X(A[0..i-1], (A[i]));
    }
}

/// Computes A := (A+1)%(2^n).
/// Allocates n-1 ancillas, but uses only [X,CNOT,CCNOT] gates.
/// This circuit is exactly as in Figure 8 in the paper.
operation Increment_v2(A : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    if (n >= 2) {
        use C = Qubit[n-1];
        CNOT(A[0], C[0]);
        for i in 1..n-2 {
            CCNOT(C[i-1], A[i], C[i]);
        }
        for i in n-1..-1..2 {
            CNOT(C[i-1], A[i]);
            CCNOT(C[i-2], A[i-1], C[i-1]);
        }
        CNOT(C[0], A[1]);
        CNOT(A[0], C[0]);
    }
    X(A[0]);
}

/// Computes A := (A+1)%(2^n).
/// Allocates n-2 ancillas, but uses only [X,CNOT,AND] gates.
/// This circuit has several further optimizations (not present in paper):
///   1. Use AND gate instead of CNOT, which has lower T-count.
///   2. Eliminate redundant first ancilla.
///   3. Custom Controlled functor (control only gates affecting register A).
operation Increment_v3(A : Qubit[]) : Unit is Adj + Ctl {
    body (...) {
        Controlled Increment_v3([], (A));
    }
    controlled (controls, ...) {
        let n = Length(A);
        if (n >= 3) {
            use C = Qubit[n-2];
            AND(A[0], A[1], C[0]);
            for i in 2..n-2 {
                AND(C[i-2], A[i], C[i-1]);
            }
            for i in n-2..-1..2 {
                Controlled CNOT(controls, (C[i-1], A[i + 1]));
                Adjoint AND(C[i-2], A[i], C[i-1]);
            }
            Controlled CNOT(controls, (C[0], A[2]));
            Adjoint AND(A[0], A[1], C[0]);
        }
        if (n >= 2) {
            Controlled CNOT(controls, (A[0], A[1]));
        }
        Controlled X(controls, (A[0]));
    }
}