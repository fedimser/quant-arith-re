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
    use C = Qubit[n-1];

    for i in n-1..-1..1 {
        within {
            CNOT(A[0], C[0]);
            for j in 1..i-1 {
                CCNOT(C[j-1], A[j], C[j]);
            }
        } apply {
            CNOT(C[i-1], A[i]);
        }
    }
    X(A[0]);
}