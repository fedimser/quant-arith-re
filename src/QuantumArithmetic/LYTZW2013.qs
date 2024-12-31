/// Implementation of incrementer presented in paper:
///   A CLASS OF EFFICIENT QUANTUM INCREMENTER GATES FOR QUANTUM CIRCUIT SYNTHESIS
///   Xiaoyu Li, Guowu Yang, Carlos Manuel Torres Jr., Desheng Zheng, Kang L. Wang, 2013.
///   https://doi.org/10.1142/S0217979213501919

/// Computes A := (A+1)%(2^n).
/// Doesn't allocate ancillas, but uses expensive multi-controlled gates.
operation Increment_v1(A: Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    for i in n-1..-1..0 {
        Controlled X(A[0..i-1], (A[i]));
    }
}

/// Computes A := (A+1)%(2^n).
operation Increment_v2(A: Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    if (n>=2) {
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