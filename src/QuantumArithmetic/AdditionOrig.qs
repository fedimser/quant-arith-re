/// Original addition algorithms.

import Std.Diagnostics.Fact;
import Std.Logical.Xor;
import QuantumArithmetic.JHHA2016;
import QuantumArithmetic.Utils;


/// Computes carries array given A, B and C[0].
/// By definition, C[i+1]=MAJ(A[i], B[i], C[i]).
/// Answer is C[1..n], which must be prepared in 0 state.
operation ComputeCarries(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(C) == n + 1, "Size mismatch.");
    for i in 0..n-1 {
        within {
            Std.Arithmetic.MAJ(A[i], B[i], C[i]);
        } apply {
            CNOT(C[i], C[i + 1]);
        }
    }
}

/// Computes Carry ⊕= (A+B)/2^n.
operation ComputeOverflowBit(A : Qubit[], B : Qubit[], Carry : Qubit) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    use C = Qubit();
    within {
        for i in 0..n-1 {
            Std.Arithmetic.MAJ(A[i], B[i], C);
        }
    } apply {
        CNOT(C, Carry);
    }
}

/// Computes C:=(A+B+(A+B)/2^n)%(2^n) which is ≡ A+B (mod 2^n-1).
operation AddMod2NMinus1OutOfPlace(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(C) == n, "Size mismatch.");
    ComputeOverflowBit(A, B, C[0]);
    ComputeCarries(A[0..n-2], B[0..n-2], C);
    Utils.ParallelCNOT(A, C);
    Utils.ParallelCNOT(B, C);
}

/// Computes B:=(A+B+(A+B)/2^n)%(2^n) which is ≡ A+B (mod 2^n-1).
/// This is needed for NZLS2023.
/// WARNING: this is incorrect for superposition states.
/// TODO: implement this correctly, as described in DKRS2004.
operation AddMod2NMinus1InPlace(A : Qubit[], B : Qubit[]) : Unit {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    use Cin = Qubit();
    ComputeOverflowBit(A, B, Cin);
    JHHA2016.AddWithInputCarry(B, Cin, A);
    Reset(Cin);
}

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
                for i in 1..n-2 {
                    CondX(A_bits[i], C[i-1]);
                    CondX(A_bits[i], B[i]);
                    CCNOT(C[i-1], B[i], C[i]);
                    CondX(A_bits[i], C[i-1]);
                    CondX(A_bits[i], B[i]);
                    CondX(A_bits[i], C[i]);
                }
                CondX(A_bits[n-1], C[n-2]);
                CondX(A_bits[n-1], B[n-1]);
            } apply {
                Controlled CCNOT(controls, (C[n-2], B[n-1], Ans));
                Controlled CondX(controls, (A_bits[n-1], Ans));
            }
        }
    }
}

/// Computes Ans ⊕= [A<B].
operation CompareConstLT(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    let n = Length(B);
    let N = 1L <<< n;
    Fact(0L <= A and A < N, "A out of range");
    OverflowBit(N-1L-A, B, Ans, false);
}

/// Computes Ans ⊕= [A<=B].
operation CompareConstLE(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    let n = Length(B);
    let N = 1L <<< n;
    Fact(0L <= A and A < N, "A out of range");
    OverflowBit(N-1L-A, B, Ans, true);
}