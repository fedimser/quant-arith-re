/// Constant Adders and Constant Comparators.
/// These are original designs, optimized for T-Count.
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;
import Std.Logical.Xor;
import QuantumArithmetic.Utils;

/// Applies X gate if control is true.
operation CondX(control : Bool, target : Qubit) : Unit is Ctl + Adj {
    if (control) {
        X(target);
    }
}

/// Computes B:=(A+B)%(2^n), controlled on `controls`.
/// Must be 1<=A<2^n, A-odd.
operation AddConstantInternal(controls : Qubit[], A : BigInt, B : Qubit[]) : Unit is Adj {
    let n = Length(B);
    let A_bits = Std.Convert.BigIntAsBoolArray(A, n);
    Fact(A_bits[0] == true, "A must be odd.");
    if (n >= 4) {
        use C = Qubit[n-3];
        Controlled CondX(controls, (A_bits[1], B[0]));
        Controlled CondX(controls, (A_bits[1], B[1]));
        AND(B[0], B[1], C[0]);
        for i in 2..n-2 {
            CondX(Xor(A_bits[i-1], A_bits[i]), C[i-2]);
            Controlled CondX(controls, (A_bits[i], B[i]));
            if (i != n-2) {
                AND(C[i-2], B[i], C[i-1]);
            }
        }
        if (Length(controls) > 0) {
            use C_last = Qubit();
            AND(C[n-4], B[n-2], C_last);
            Controlled CNOT(controls, (C_last, B[n-1]));
            Adjoint AND(C[n-4], B[n-2], C_last);
        } else {
            CCNOT(C[n-4], B[n-2], B[n-1]);
        }
        for i in n-2..-1..2 {
            if (i != n-2) {
                Controlled CNOT(controls, (C[i-1], B[i + 1]));
                CondX(A_bits[i], C[i-1]);
                Adjoint AND(C[i-2], B[i], C[i-1]);
            }
            CondX(A_bits[i], C[i-2]);
        }
        Controlled CNOT(controls, (C[0], B[2]));
        CondX(A_bits[1], C[0]);
        Adjoint AND(B[0], B[1], C[0]);
        Controlled CondX(controls, (A_bits[1], B[0]));
        Controlled CondX(controls, (Xor(A_bits[n-2], A_bits[n-1]), B[n-1]));
    } elif (n == 3) {
        Controlled CondX(controls, (A_bits[1], B[0]));
        Controlled CondX(controls, (A_bits[1], B[1]));
        if (Length(controls) > 0) {
            use C0 = Qubit();
            AND(B[0], B[1], C0);
            Controlled CNOT(controls, (C0, B[2]));
            Adjoint AND(B[0], B[1], C0);
        } else {
            CCNOT(B[0], B[1], B[2]);
        }
        Controlled CondX(controls, (A_bits[1], B[0]));
        Controlled CondX(controls, (Xor(A_bits[1], A_bits[2]), B[n-1]));
    } elif (n == 2) {
        Controlled CondX(controls, (A_bits[1], B[1]));
    }
    if (n >= 2) {
        Controlled CNOT(controls, (B[0], B[1]));
    }
    Controlled X(controls, (B[0]));
}

/// Computes B:=(A+B)%(2^n).
operation AddConstant(A : BigInt, B : Qubit[]) : Unit is Ctl + Adj {
    body (...) {
        Controlled AddConstant([], (A, B));
    }
    controlled (controls, ...) {
        let n = Length(B);
        let N = 1L <<< n;
        let A = ((A % N) + N) % N;
        if (A != 0L) {
            let tz = Std.Math.TrailingZeroCountL(A);
            AddConstantInternal(controls, A >>> tz, B[tz...]);
        }
    }
}

/// Computes Ans⊕=(A+B+CarryIn)/(2^n).
operation OverflowBit(A : BigInt, B : Qubit[], Ans : Qubit, CarryIn : Bool) : Unit is Adj + Ctl {
    body (...) {
        Controlled OverflowBit([], (A, B, Ans, CarryIn));
    }
    controlled (controls, ...) {
        let n = Length(B);
        let A_bits = Std.Convert.BigIntAsBoolArray(A, n);
        if (n == 1) {
            if (CarryIn) {
                if (A_bits[0]) {
                    Controlled X(controls, (Ans));
                } else {
                    Controlled CNOT(controls, (B[0], Ans));
                }
            } else {
                Controlled CondX(controls + [B[0]], (A_bits[0], Ans));
            }
        } else {
            use C = Qubit[n-1];
            within {
                if (CarryIn) {
                    if (A_bits[0]) {
                        X(C[0]);
                    } else {
                        CNOT(B[0], (C[0]));
                    }
                } else {
                    Controlled CondX([B[0]], (A_bits[0], C[0]));
                }
                CondX(A_bits[1], C[0]);
                for i in 1..n-2 {
                    CondX(A_bits[i], B[i]);
                    AND(C[i-1], B[i], C[i]);
                    CondX(Xor(A_bits[i], A_bits[i + 1]), C[i]);
                }
                CondX(A_bits[n-1], B[n-1]);
            } apply {
                Controlled CCNOT(controls, (C[n-2], B[n-1], Ans));
                Controlled CondX(controls, (A_bits[n-1], Ans));
            }
        }
    }
}

/// Computes Ans ⊕= [A<B].
operation CompareByConstLT(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    let n = Length(B);
    let N = 1L <<< n;
    Fact(0L <= A and A < N, "A out of range");
    OverflowBit(N-1L-A, B, Ans, false);
}

/// Computes Ans ⊕= [A<=B].
operation CompareByConstLE(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    let n = Length(B);
    let N = 1L <<< n;
    Fact(0L <= A and A < N, "A out of range");
    OverflowBit(N-1L-A, B, Ans, true);
}

/// Computes Ans ⊕= [A>B].
operation CompareByConstGT(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    CompareByConstLE(A, B, Ans);
    X(Ans);
}

/// Computes Ans ⊕= [A>=B].
operation CompareByConstGE(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    CompareByConstLT(A, B, Ans);
    X(Ans);
}

export AddConstant, CompareByConstLT, CompareByConstLE, CompareByConstGT, CompareByConstGE;