namespace QuantumArithmetic {
    import Std.Diagnostics.Fact;

    // Computes a,b,c:=(a%b,b,a/b).
    // * c must be initialized to zeros.
    // * a,b,c must have the same number of qubits n.
    // * Constraints: 0<=a<2^n, 0<b<2^(n-1). 
    // All numbers are little-endian.
    // Ref: Thapliyal et al., 2019, https://arxiv.org/pdf/1809.09732 (Algorithm 1).
    operation Divide_TMVH_Restoring(a : Qubit[], b : Qubit[], c : Qubit[]) : Unit is Adj + Ctl {
        let R = c;
        let Q = a;
        let n = Length(Q);
        Fact(n == Length(b), "Registers sizes must match.");
        Fact(n == Length(R), "Registers sizes must match.");

        for i in 1..n {
            let Y = Q[n-i..n-1] + R[0..n-1-i];
            Subtract(b, Y);
            CX(Y[n-1], R[n-i]);
            Controlled Add_RippleCarryTTK([R[n-i]], (b, Y));
            X(R[n-i]);
        }
    }
}