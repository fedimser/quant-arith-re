/// Implementation of Greatest Common Divisor presented in paper:
///   Quantum Circuits for GCD Computation with O(nlogn) Depth and O(n) Ancillae
///   Mehdi Saeedi and Igor L. Markov, 2013.
///   https://arxiv.org/abs/1304.7516
/// All numbers are unsigned integer, little-endian.

import Std.Diagnostics.Fact;
import QuantumArithmetic.Utils;

// Ans := (A%2==0).
operation IsEven(A : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    X(A[0]);
    CNOT(A[0], Ans);
    X(A[0]);
}

/// Ans := (A==0).
operation IsZero(A : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    Std.Arithmetic.ApplyIfEqualL(X, 0L, A, Ans);
}

/// Computes Ans:=GCD(A,B).
/// Must be 0<=A<2^n, 0<=B<2^n.
/// Classical algorithm: https://github.com/fedimser/quant_comp/blob/master/arithmetic/gcd_stein.ipynb
operation GreatestCommonDivisor(A : Qubit[], B : Qubit[], Ans : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(Length(Ans) == n, "Register sizes must match.");
    Fact(n >= 2, "n must be at least 2.");
    let iters = 2 * n-3;
    use R = Qubit[n];
    use Anc = Qubit[4 * iters + 1];

    within {
        X(R[0]); // R:=1.
        for i in 0..iters-1 {
            // Each iteration uses 4 ancillas.
            let AIsNotZero = Anc[4 * i];
            IsZero(A, AIsNotZero);
            X(AIsNotZero);
            let AIsEven = Anc[4 * i + 1];
            IsEven(A, AIsEven);
            let BIsEven = Anc[4 * i + 2];
            IsEven(B, BIsEven);
            Controlled Utils.RotateRight([AIsNotZero, AIsEven], A);
            Controlled Utils.RotateRight([AIsNotZero, BIsEven], B);
            Controlled Utils.RotateLeft([AIsNotZero, AIsEven, BIsEven], R);
            let ALessB = Anc[4 * i + 3];
            Std.Arithmetic.ApplyIfLessLE(X, A, B, ALessB);
            Controlled Utils.ParallelSWAP([AIsNotZero, ALessB], (A, B));
            X(AIsEven);
            X(BIsEven);
            Controlled Utils.Subtract([AIsEven, BIsEven], (B, A)); // A-=B.
            Controlled Utils.RotateRight([AIsEven, BIsEven], (A)); // A/=2.
        }
        // This last step is needed to handle case when B=0 in input..
        let BIsZero = Anc[4 * iters];
        IsZero(B, BIsZero);
        Controlled Utils.ParallelSWAP([BIsZero], (A, B));
    } apply {
        // Ans = B * R, assuming R is a power of two.
        for i in 0..n-1 {
            Controlled Utils.ParallelCNOT([R[i]], (B[0..n-1-i], Ans[i..n-1]));
        }
    }
}