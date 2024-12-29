/// Implementation of operations presented in paper:
///   CNOT-count optimized quantum circuit of the Shor’s algorithm
///   Xia Liu, Huan Yang, Li Yang, 2021.
///   https://arxiv.org/abs/2112.11358
/// All numbers are unsigned integers, little-endian.

import Std.Arithmetic.IncByLUsingIncByLE;
import Std.Diagnostics.Fact;
import Std.Math.*;

import QuantumArithmetic.CDKM2004;
import QuantumArithmetic.AdditionOrig;
import QuantumArithmetic.Utils;


/// Computes B+=A modulo 2^n.
operation Add(A: Qubit[], B: Qubit[]) : Unit is Adj + Ctl {
    CDKM2004.Add(A, B);
}

/// Computes X+=A modulo 2^n.
operation AddConstant(A: BigInt, B: Qubit[]) : Unit is Adj + Ctl {
    IncByLUsingIncByLE(Add, A, B);
}

/// Computes B+=ctrl*A modulo 2^n.
operation CtrlAdd(ctrl: Qubit, A: Qubit[], B: Qubit[]) : Unit is Adj + Ctl{
    Controlled Add([ctrl], (A, B));
}

/// Computes X+=ctrl*A modulo 2^n.
operation CtrlAddConstant(ctrl: Qubit, A: BigInt, B: Qubit[]) : Unit is Adj + Ctl{
    if A != 0L {
        let j = TrailingZeroCountL(A);
        if (j>0) {
            CtrlAddConstant(ctrl, A>>>j, B[j...]);
        } else {
            use Atmp = Qubit[Length(B)];
            within {
                Controlled ApplyXorInPlaceL([ctrl], (A, Atmp));
            } apply {
                Add(Atmp, B);
            }
        }
    }
}

/// Computes Ans ⊕= [A>B].
operation Compare(A: Qubit[], B: Qubit[], Ans: Qubit): Unit is Adj + Ctl{
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
        CNOT(B[n-1], Ans);
    }
}

/// Computes Ans ⊕= [A>B].
operation CompareByConst(A: BigInt, B: Qubit[], Ans: Qubit): Unit is Adj + Ctl{
    use Atmp = Qubit[Length(B)];
    within {
        ApplyXorInPlaceL((A, Atmp));
    } apply {
        Compare(Atmp,B, Ans);
    }
}

// TODO: optimize!
operation CtrlCompare(ctrl: Qubit, A: Qubit[], B: Qubit[], Ans: Qubit): Unit is Adj + Ctl{
    Controlled Compare([ctrl], (A, B, Ans));
}

/// Computes B:=2*B, when the highest bit is known to be 0.
/// Figure 10 in the paper.
operation LeftShift(B: Qubit[]): Unit is Adj + Ctl{
    let n = Length(B);
    for i in n-2..-1..0 {
        CNOT(B[i], B[i+1]);
        CNOT(B[i+1], B[i]);
    }
}

/// Computes A ⊕= (1-ctrl)*B. 
operation XorIfZero(ctrl: Qubit, A: Qubit[], B: BigInt): Unit is Adj + Ctl {
    X(ctrl);
    Controlled ApplyXorInPlaceL([ctrl], (B, A));
    X(ctrl);
}

operation XorIfOne(ctrl: Qubit, A: Qubit[], B: BigInt): Unit is Adj + Ctl {
    Controlled ApplyXorInPlaceL([ctrl], (B, A));
}

/// Computes B:=(A+B)%N.
/// Must be 0 <= A,B < N < 2^N.
/// Figure 8 in the paper.
operation ModAdd(A: Qubit[], B: Qubit[], N: BigInt): Unit is Adj + Ctl  {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(N >= 2L, "N must be at least 2.");
    Fact(N < 1L<<<n, "N is too large.");
    use Anc = Qubit[n+2];

    CDKM2004.AddWithCarry(A, B, Anc[n]);
    CompareByConst(N, B, Anc[n]);
    CNOT(Anc[n], Anc[n+1]);    
    CNOT(Anc[n+1], Anc[n]);
    within {
        X(Anc[n+1]);
        Controlled ApplyXorInPlaceL([Anc[n+1]], (N, Anc[0..n-1]));
    } apply {
        Adjoint CDKM2004.Add(Anc[0..n-1], B);
    }
    Compare(A, B, Anc[n+1]);
    X(Anc[n+1]);
}

/// Figure 9 in the paper.
operation CtrlModAdd(ctrl: Qubit, A: Qubit[], B: Qubit[]): Unit is Adj + Ctl{
}

/// Computes A:=(2*A)%N.
/// Figure 11 in the paper.
operation ModDbl(A: Qubit[], N: BigInt): Unit is Adj + Ctl{
}
