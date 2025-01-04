import QuantumArithmetic.Utils.ParallelCNOT;
import QuantumArithmetic.Utils.Rearrange2D;
/// Implementation of operations presented in paper:
///   CNOT-count optimized quantum circuit of the Shor’s algorithm
///   Xia Liu, Huan Yang, Li Yang, 2021.
///   https://arxiv.org/abs/2112.11358
/// All numbers are unsigned integers, little-endian.

import Std.Arithmetic.IncByLUsingIncByLE;
import Std.Diagnostics.Fact;
import Std.Math;

import QuantumArithmetic.CDKM2004;
import QuantumArithmetic.AdditionOrig;
import QuantumArithmetic.Utils;


/// Computes B+=A modulo 2^n.
operation Add(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    CDKM2004.Add(A, B);
}

/// Computes X+=A modulo 2^n.
/// Figures 5, 6 from the paper.
operation AddConstant(A : BigInt, B : Qubit[]) : Unit is Adj + Ctl {
    body (...) {
        IncByLUsingIncByLE(Add, A, B);
    }
    controlled (controls, ...) {
        if A != 0L {
            let n = Length(B);
            let j = Math.TrailingZeroCountL(A);
            use Atmp = Qubit[n - j];
            within {
                Controlled ApplyXorInPlaceL(controls, (A >>> j, Atmp));
            } apply {
                Add(Atmp, B[j...]);
            }
        }
    }
}

/// Computes X-=A modulo 2^n.
operation SubtractConstant(A : BigInt, B : Qubit[]) : Unit is Adj + Ctl {
    Adjoint AddConstant(A, B);
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

/// Computes B:=B/2, when the lowest bit is known to be 0.
operation RightShift(B : Qubit[]) : Unit is Adj + Ctl {
    Adjoint LeftShift(B);
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
        use Anc = Qubit[2];

        Controlled CDKM2004.AddWithCarry(controls, (A, B, Anc[0]));
        CompareByConst(N, B, Anc[0]);
        CNOT(Anc[0], Anc[1]);
        CNOT(Anc[1], Anc[0]);
        X(Anc[1]);
        Controlled SubtractConstant([Anc[1]], (N, B));
        Controlled Compare(controls, (A, B, Anc[1]));
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
/// Must be 0 <= B < N < 2^n.
/// C must be prepared in zero state.
/// Figure 15 in the paper.
operation ModMulFast(A : Qubit[], B : Qubit[], C : Qubit[], N : BigInt) : Unit is Adj + Ctl {
    let n1 = Length(A);
    let n2 = Length(B);
    Fact(Length(C) == n2, "Size mismatch.");
    for i in 0..n2-1 {
        CCNOT(A[n1-1], B[i], C[i]);
    }
    for i in n1-2..-1..0 {
        ModDbl(C, N);
        Controlled ModAdd([A[i]], (B, C, N));
    }
}

/// Modular multiplication by a constant, based on ModMulFast.
/// Computes C:=(A*B)%N.
/// C must be prepared in zero state.
/// Figure 15 in the paper, considering x to be classical bits.
operation ModMulByConstFast(B : Qubit[], C : Qubit[], A : BigInt, N : BigInt) : Unit is Adj + Ctl {
    body (...) {
        Controlled ModMulByConstFast([], (B, C, A, N));
    }
    controlled (controls, ...) {
        let A = ((A % N) + N) % N;
        if (A != 0L) {
            let n1 = Utils.FloorLog2(A) + 1;
            let A_bits = Std.Convert.BigIntAsBoolArray(A, n1);
            let n2 = Length(B);
            Fact(Length(C) == n2, "Size mismatch.");
            Controlled Utils.ParallelCNOT(controls, (B, C));
            for i in n1-2..-1..0 {
                ModDbl(C, N);
                if (A_bits[i]) {
                    Controlled ModAdd(controls, (B, C, N));
                }
            }
        }
    }
}

/// Computes Ans=(a^x)%N.
/// Ans must be prepared in zero state.
/// a must be co-prime with N.
/// Doesn't change x.
/// Figure 4 in the paper.
operation ModExp(x : Qubit[], Ans : Qubit[], a : BigInt, N : BigInt) : Unit is Adj + Ctl {
    let n1 = Length(x);
    let n2 = Length(Ans);
    let a_sqs = Utils.ComputeSequentialSquares(a, N, n1);
    let a_inv_sqs = Utils.ComputeSequentialSquares(Utils.ModInv(a, N), N, n1);

    use Anc = Qubit[n2];
    X(Ans[0]); // Ans:=1.
    for i in 0..n1-1 {
        Controlled ModMulByConstFast([x[i]], (Ans, Anc, a_sqs[i], N));
        Controlled Utils.ParallelSWAP([x[i]], (Ans, Anc));
        Adjoint Controlled ModMulByConstFast([x[i]], (Ans, Anc, a_inv_sqs[i], N));
    }
}

/// Controlled table lookup.
operation TableLookupCtl(control : Qubit, input : Qubit[], target : Qubit[], table : BigInt[]) : Unit is Adj {
    let m = Length(input);
    let tn = Length(table);
    Fact(tn == 1 <<< m, "Table size must be 2^m.");

    if (m == 0) {
        Controlled ApplyXorInPlaceL([control], (table[0], target));
    } else {
        use anc = Qubit();
        X(input[m-1]);
        within {
            AND(control, input[m-1], anc);
        } apply {
            X(input[m-1]);
            TableLookupCtl(anc, input[0..m-2], target, table[0..tn / 2-1]);
            CNOT(control, anc);
            TableLookupCtl(anc, input[0..m-2], target, table[tn / 2..tn-1]);
        }

    }
}

/// Assigns target ⊕= table[input].
/// Figure 13 in the paper.
/// Originally idea comes from https://arxiv.org/abs/1805.03662.
operation TableLookup(input : Qubit[], target : Qubit[], table : BigInt[]) : Unit is Adj + Ctl {
    body (...) {
        let m = Length(input);
        let tn = Length(table);
        X(input[m-1]);
        TableLookupCtl(input[m-1], input[0..m-2], target, table[0..tn / 2-1]);
        X(input[m-1]);
        TableLookupCtl(input[m-1], input[0..m-2], target, table[tn / 2..tn-1]);
    }
    controlled (controls, ...) {
        if (Length(controls) == 0) {
            TableLookup(input, target, table);
        } else {
            Fact(Length(controls) <= 1, "Only up to 1 control is supported.");
            TableLookupCtl(controls[0], input, target, table);
        }
    }
}

function MakeLookupTable(a : BigInt[], N : BigInt) : BigInt[] {
    let m = Length(a);
    if (m == 1) {
        return [1L, a[0]];
    } else {
        mutable ans = MakeLookupTable(a[0..m-2], N);
        for i in 0..(1 <<< (m-1))-1 {
            set ans += [(ans[i] * a[m-1]) % N];
        }
        return ans;
    }
}

/// Computes Ans=(a^x)%N.
/// Ans must be prepared in zero state. a can be anything. Doesn't change x.
/// Figure 14 in the paper.
operation ModExpWindowed(
    x : Qubit[],
    Ans : Qubit[],
    a : BigInt,
    N : BigInt,
    window_size : Int
) : Unit is Adj + Ctl {
    let n1 = Length(x);
    let n2 = Length(Ans);
    let a_sqs = Utils.ComputeSequentialSquares(a, N, n1);
    let window_count = Utils.DivCeil(n1, window_size);
    use Anc1 = Qubit[window_count * n2];
    let y : Qubit[][] = Rearrange2D(Anc1, window_count, n2);  // Intermediary results.
    use Anc2 = Qubit[window_count * n2];
    let lkp : Qubit[][] = Rearrange2D(Anc2, window_count, n2); // Looked up values.
    within {
        X(y[0][0]);  // y[0] := 1.
        for i in 0..window_count-2 {
            let x_range = i * window_size..(i * window_size + window_size-1);
            TableLookup(x[x_range], lkp[i], MakeLookupTable(a_sqs[x_range], N));
            ModMulFast(lkp[i], y[i], y[i + 1], N);
        }
        let x_range = (window_count-1) * window_size..n1-1;
        TableLookup(x[x_range], lkp[window_count-1], MakeLookupTable(a_sqs[x_range], N));
    } apply {
        ModMulFast(lkp[window_count-1], y[window_count-1], Ans, N);
    }
}

/// Figure 17 in the paper.
/// Classical algorithm originally descibed in: http://jstor.org/stable/2007970
operation ForwardMontgomery(x : Qubit[], y : Qubit[], Ans : Qubit[], Anc : Qubit[], N : BigInt) : Unit is Adj + Ctl {
    let n1 = Length(x);
    let n2 = Length(y);
    Fact(N <= 1L <<< (n2-1), "N too large.");
    Fact(Length(Ans) == n2, "Size mismatch.");
    Fact(Length(Anc) == n2 + 2, "Size mismatch.");

    for i in 0..n1-1 {
        if (i == 0) {
            Controlled ParallelCNOT([x[0]], (y, Ans));
        } else {
            Controlled CDKM2004.AddWithCarry([x[i]], (y, Ans, Anc[0]));
        }
        CNOT(Ans[0], Anc[i + 1]);
        Controlled AddConstant([Anc[i + 1]], (N, Ans + [Anc[0]]));
        RightShift(Ans + [Anc[0]]);
    }
    CompareByConst(N, Ans + [Anc[0]], Anc[n2 + 1]);
    X(Anc[n2 + 1]);
    Controlled SubtractConstant([Anc[n2 + 1]], (N, Ans + [Anc[0]]));
}

/// Computes Ans ⊕= ((x*y)/2^n2)%N, where n2=Length(y).
/// Doesn't change x, y.
/// Constraints: 0<=y<N, 3<=N<=2^n2-1, N-odd.
/// Figure 16 in the paper.
operation ModMulMontgomery(x : Qubit[], y : Qubit[], Ans : Qubit[], N : BigInt) : Unit is Adj + Ctl {
    let n2 = Length(y);
    Fact(Length(Ans) == n2, "Size mismatch.");
    Fact(N % 2L == 1L, "N must be odd.");
    Fact(N < (1L <<< n2), "N too large.");
    if (N > 1L <<< (n2-1)) {
        // Need to pad y with extra qubit.
        use y_pad = Qubit();
        use TmpAns = Qubit[n2 + 1];
        use Anc = Qubit[n2 + 3];
        within {
            ForwardMontgomery(x, y + [y_pad], TmpAns, Anc, N);
        } apply {
            ParallelCNOT(TmpAns[0..n2-1], Ans);
        }
    } else {
        use TmpAns = Qubit[n2];
        use Anc = Qubit[n2 + 2];
        within {
            ForwardMontgomery(x, y, TmpAns, Anc, N);
        } apply {
            ParallelCNOT(TmpAns, Ans);
        }
    }
}

/// Computes Ans=(a^x)%N.
/// Ans must be prepared in zero state. a can be anything. Doesn't change x.
/// Figure 14 in the paper.
/// With window_size=1, equivalent to Figure 12.
operation ModExpWindowedMontgomery(
    x : Qubit[],
    Ans : Qubit[],
    a : BigInt,
    N : BigInt,
    window_size : Int
) : Unit is Adj + Ctl {
    let n1 = Length(x);
    let n2 = Length(Ans);
    let a_sqs = Utils.ComputeSequentialSquares(a, N, n1);
    let window_count = Utils.DivCeil(n1, window_size);
    use Anc1 = Qubit[window_count * n2];
    let y : Qubit[][] = Rearrange2D(Anc1, window_count, n2);  // Intermediary results.
    use Anc2 = Qubit[window_count * n2];
    let lkp : Qubit[][] = Rearrange2D(Anc2, window_count, n2); // Looked up values.
    within {
        X(y[0][0]);  // y[0] := 1.
        for i in 0..window_count-2 {
            let x_range = i * window_size..(i * window_size + window_size-1);
            let lookup_table = Std.Arrays.Mapped(x -> (x <<< n2) % N, MakeLookupTable(a_sqs[x_range], N));
            TableLookup(x[x_range], lkp[i], lookup_table);
            ModMulMontgomery(lkp[i], y[i], y[i + 1], N);
        }
        let x_range = (window_count-1) * window_size..n1-1;
        let lookup_table = Std.Arrays.Mapped(x -> (x <<< n2) % N, MakeLookupTable(a_sqs[x_range], N));
        TableLookup(x[x_range], lkp[window_count-1], lookup_table);
    } apply {
        ModMulMontgomery(lkp[window_count-1], y[window_count-1], Ans, N);
    }
}

export ModExp, ModExpWindowed, ModExpWindowedMontgomery, TableLookup;
