import QuantumArithmetic.CDKM2004.AddWithCarry;
/// Implementation of operations presented in paper:
///   CNOT-count optimized quantum circuit of the Shor’s algorithm
///   Xia Liu, Huan Yang, Li Yang, 2021.
///   https://arxiv.org/abs/2112.11358
/// All numbers are unsigned integers, little-endian.

import Std.Arithmetic.IncByLUsingIncByLE;
import Std.Arrays.*;
import Std.Diagnostics.Fact;
import Std.Math.*;

import QuantumArithmetic.CDKM2004;
import QuantumArithmetic.AdditionOrig;
import QuantumArithmetic.Utils;


/// Computes B+=A modulo 2^n.
operation Add(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    CDKM2004.Add(A, B);
}

/// Computes X+=A modulo 2^n.
operation AddConstant(A : BigInt, B : Qubit[]) : Unit is Adj + Ctl {
    body (...) {
        IncByLUsingIncByLE(Add, A, B);
    }
    controlled (controls, ...) {
        if A != 0L {
            let n = Length(B);
            let j = TrailingZeroCountL(A);
            use Atmp = Qubit[n - j];
            within {
                Controlled ApplyXorInPlaceL(controls, (A >>> j, Atmp));
            } apply {
                Add(Atmp, B[j...]);
            }
        }
    }
}

/// Computes Ans ⊕= [A>B].
operation Compare(A : Qubit[], B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    body (...) {
        Controlled Compare([], (A, B, Ans));
    }
    controlled (controls, ...) {
        let n = Length(A);
        Fact(Length(B) == n, "Size mismatch.");
        use Anc = Qubit();
        within {
            Utils.ParallelX(B);
            Std.Arithmetic.MAJ(Anc, A[0], B[0]);
            for i in 1..n-1 {
                Std.Arithmetic.MAJ(B[i-1], A[i], B[i]);
            }
        } apply {
            Controlled CNOT(controls, (B[n-1], Ans));
        }
    }
}

/// Computes Ans ⊕= [A>B].
operation CompareByConst(A : BigInt, B : Qubit[], Ans : Qubit) : Unit is Adj + Ctl {
    use Atmp = Qubit[Length(B)];
    within {
        ApplyXorInPlaceL((A, Atmp));
    } apply {
        Compare(Atmp, B, Ans);
    }
}

/// Computes B:=2*B, when the highest bit is known to be 0.
/// Figure 10 in the paper.
operation LeftShift(B : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(B);
    for i in n-2..-1..0 {
        CNOT(B[i], B[i + 1]);
        CNOT(B[i + 1], B[i]);
    }
}

/// Computes B:=(A+B)%N.
/// Must be 0 <= A,B < N < 2^N.
/// Figures 8 and 9 in the paper.
operation ModAdd(A : Qubit[], B : Qubit[], N : BigInt) : Unit is Adj + Ctl {
    body (...) {
        Controlled ModAdd([], (A, B, N));
    }
    controlled (controls, ...) {
        let n = Length(A);
        Fact(Length(B) == n, "Size mismatch.");
        Fact(N >= 2L, "N must be at least 2.");
        Fact(N < 1L <<< n, "N is too large.");
        use Anc = Qubit[n + 2];

        Controlled CDKM2004.AddWithCarry(controls, (A, B, Anc[n]));
        CompareByConst(N, B, Anc[n]);
        CNOT(Anc[n], Anc[n + 1]);
        CNOT(Anc[n + 1], Anc[n]);
        X(Anc[n + 1]);
        within {
            Controlled ApplyXorInPlaceL([Anc[n + 1]], (N, Anc[0..n-1]));
        } apply {
            Adjoint CDKM2004.Add(Anc[0..n-1], B);
        }
        Controlled Compare(controls, (A, B, Anc[n + 1]));
    }
}

/// Computes A:=(2*A)%N.
/// Must be 0 <= A < N < 2^n. N must be odd.
/// Figure 11 in the paper.
operation ModDbl(A : Qubit[], N : BigInt) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(N >= 3L, "N must be at least 3.");
    Fact(N % 2L == 1L, "N must be odd.");
    Fact(N < (1L <<< n), "N is too large.");
    use Anc = Qubit[n + 2];

    LeftShift(A + [Anc[n]]);
    CompareByConst(N, A + [Anc[n]], Anc[n + 1]);
    X(Anc[n + 1]);
    within {
        Controlled ApplyXorInPlaceL([Anc[n + 1]], (N, Anc[0..n-1]));
    } apply {
        Adjoint CDKM2004.AddWithCarry(Anc[0..n-1], A, Anc[n]);
    }
    CNOT(A[0], Anc[n + 1]);
}

/// Fast modular multiplication.
/// Computes C:=(A*B)%N.
/// C must be prepared in zero state.
/// Figure 15 in the paper.
operation ModMulFast(A : Qubit[], B : Qubit[], C : Qubit[], N : BigInt) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    for i in 0..n-1 {
        CCNOT(A[n-1], B[i], C[i]);
    }
    for i in n-2..-1..0 {
        ModDbl(C, N);
        Controlled ModAdd([A[i]], (B, C, N));
    }
}