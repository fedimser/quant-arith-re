/// Implementation of in-place adders presented in paper:
///   A logarithmic-depth quantum carry-lookahead adder.
///   Thomas G. Draper, Samuel A. Kutin, Eric M. Rains, Krysta M. Svore.
///   https://arxiv.org/abs/quant-ph/0406142
/// Note that out-of-place adder modulo 2^n from this paper is implemented in 
/// Std.Arithmetic.LookAheadDKRSAddLE.
/// This file uses some helpers copied from Std.ArithmeticUtils.

import Std.Arrays.*;
import Std.Convert.IntAsDouble;
import Std.Diagnostics.Fact;
import Std.Math.*;
import QuantumArithmetic.Utils.*;

/// TODO: use ApplyAndAssuming0Target when it becomes intrinsic.
operation ApplyAndAssuming0Target(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit is Adj + Ctl {
    CCNOT(control1, control2, target);
}

/// Copied from Std.ArithmeticUtils.
operation PRounds(pWorkspace : Qubit[][]) : Unit is Adj + Ctl {
    for ws in Windows(2, pWorkspace) {
        let (current, next) = (Rest(ws[0]), ws[1]);
        for m in IndexRange(next) {
            ApplyAndAssuming0Target(current[2 * m], current[2 * m + 1], next[m]);
        }
    }
}

/// Copied from Std.ArithmeticUtils.
operation GRounds(pWorkspace : Qubit[][], gs : Qubit[]) : Unit is Adj + Ctl {
    let T = Length(pWorkspace);
    let n = Length(gs);
    for t in 1..T {
        let length = Floor(IntAsDouble(n) / IntAsDouble(2^t)) - 1;
        let ps = pWorkspace[t - 1][0..2...];
        for m in 0..length {
            CCNOT(gs[2^t * m + 2^(t - 1) - 1], ps[m], gs[2^t * m + 2^t - 1]);
        }
    }
}

/// Copied from Std.ArithmeticUtils.
operation CRounds(pWorkspace : Qubit[][], gs : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(gs);
    let start = Floor(Lg(IntAsDouble(2 * n) / 3.0));
    for t in start..-1..1 {
        let length = Floor(IntAsDouble(n - 2^(t - 1)) / IntAsDouble(2^t));
        let ps = pWorkspace[t - 1][1..2...];

        for m in 1..length {
            CCNOT(gs[2^t * m - 1], ps[m - 1], gs[2^t * m + 2^(t - 1) - 1]);
        }
    }
}

/// Circuit from §3.
/// Copied from Std.ArithmeticUtils.
operation ComputeCarries(ps : Qubit[], gs : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(gs);
    Fact(Length(ps) + 1 == n, "Register gs must be one qubit longer than register gs.");
    let T = Floor(Lg(IntAsDouble(n)));
    use qs = Qubit[n - HammingWeightI(n) - T];
    let registerPartition = MappedOverRange(t -> Floor(IntAsDouble(n) / IntAsDouble(2^t)) - 1, 1..T - 1);
    let pWorkspace = [ps] + Partitioned(registerPartition, qs);
    within {
        PRounds(pWorkspace);
    } apply {
        GRounds(pWorkspace, gs);
        CRounds(pWorkspace, gs);
    }
}

/// Algorithm from §4.2.
/// If Length(Z)==n, does addition with carry, using Z[n-1] as carry bit.
/// If Length(Z)==n-1, does addition without carry.
operation InPlaceAddHelper(A : Qubit[], B : Qubit[], Z: Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(B) == n, "Size mismatch.");
    let Zn = Length(Z);
    Fact(Zn == n or Zn==n-1, "Size mismatch.");
    
    for i in 0..Zn - 1 {
        ApplyAndAssuming0Target(A[i], B[i], Z[i]);
    }
    ParallelCNOT(A, B);
    if n > 1 {
        ComputeCarries(B[1..Zn-1], Z[0..Zn-1]);
    }
    ParallelCNOT(Z[0..n-2], B[1..n-1]);
    ParallelX(B[0..n-2]);
    ParallelCNOT(A[1..n-2], B[1..n-2]);
    if n > 1 {
        Adjoint ComputeCarries(B[1..n-2], Z[0..n-2]);
    }
    ParallelCNOT(A[1..n-2], B[1..n-2]);
    for i in 0..n - 2 {
        Adjoint ApplyAndAssuming0Target(A[i], B[i], Z[i]);
    }
    ParallelX(B[0..n-2]);
}

/// Computes B+=A mod (2^n).
operation Add(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    use Z = Qubit[Length(A)-1];
    InPlaceAddHelper(A, B, Z);
}

/// Computes B+=A mod (2^n), Carry=(A+B)/(2^n).
/// Carry must be prepared in zero state.
operation AddWithCarry(A : Qubit[], B : Qubit[], Carry: Qubit) : Unit is Adj + Ctl {
    use Z = Qubit[Length(A)-1];
    InPlaceAddHelper(A, B, Z + [Carry]);
}

/// Computes carries array given A, B and C[0].
/// By definition, C[i+1]=MAJ(A[i], B[i], C[i]).
/// Answer is C[1..n], which must be prepared in 0 state.
operation ComputeCarriesSimple(A : Qubit[], B : Qubit[], C : Qubit[]): Unit is Adj + Ctl  {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(C) == n+1, "Size mismatch.");
    for i in 0..n-1 {
        within{
            Std.Arithmetic.MAJ(A[i], B[i], C[i]);
        } apply {
            CNOT(C[i], C[i+1]);
        }
    }
}

/// Computes (A+B)/2^n.
operation ComputeOverflowBitSimple(A : Qubit[], B : Qubit[], Carry : Qubit): Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    use C = Qubit[n+1];
    within {
        ComputeCarriesSimple(A,B,C);
    } apply {
        CNOT(C[n], Carry);
    }
}

/// Inefficient (O(n) depth) implementation of adder modulo 2^n-1.
/// Computes C:=(A+B)%(2^n-1).
/// TODO: implement efficient adder from the paper.
operation AddMod2nm1OutOfPlace(A : Qubit[], B : Qubit[], C : Qubit[]): Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(C) == n, "Size mismatch.");
    ComputeOverflowBitSimple(A, B, C[0]);
    ComputeCarriesSimple(A[0..n-2], B[0..n-2], C);
    ParallelCNOT(A, C);
    ParallelCNOT(B, C);
}

export Add, AddWithCarry;