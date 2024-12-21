import Std.Math.GreatestCommonDivisorL;
import Std.Math.GreatestCommonDivisorI;
import QuantumArithmetic.Utils.ParallelCNOT;
/// Implementation of operations presented in paper:
///   Fast quantum modular exponentiation architecture for Shor's factoring algorithm
///   Archimedes Pavlidis and Dimitris Gizopoulos, 2012.
///   https://arxiv.org/pdf/1207.0511
/// All numbers are unsigned integer, little-endian.

import Std.Arrays.*;
import Std.Convert.*;
import Std.Diagnostics.Fact;
import Std.Math;

import QuantumArithmetic.Utils;

// Applies gate diag(1, exp(i*pi*n/2^k)).
// Note: for algorithm implementation to be correct in principle, we need to
// assume that we can apply rotation with arbitrary precision, this is why we
// have this operation.
// However, with current implementation n is converted to double, so if it has
// more than 52 significant bits, precision will be lost.
operation R1Precise(n : BigInt, k : Int, qubit : Qubit) : Unit is Ctl + Adj {
    if (n < 0L) {
        Adjoint R1Precise(-n, k, qubit);
    } else {
        let bs : Int = Math.BitSizeL(n);
        if (bs > 63) {
            R1Precise(n >>> (bs-63), k-(bs-63), qubit);
        } else {
            R1Frac(BoolArrayAsInt(BigIntAsBoolArray(n, bs)), k, qubit);
        }
    }
}

// Adder (ΦADD) from §2.3.
// Computes b+=a, where b_f=QFT(b).
operation FADD(a : BigInt, b_f : Qubit[]) : Unit is Ctl + Adj {
    let n = Length(b_f);
    for j in 0..n-1 {
        let phase = 2L * (a % (1L <<< (j + 1)));
        R1Precise(phase, j + 1, b_f[j]);
    }
}

operation PhaseGradient(qs : Qubit[]) : Unit is Adj + Ctl {
    for i in IndexRange(qs) {
        R1Precise(1L, i, qs[i]);
    }
}

// Adds two quantum numbers: b+=a, where b_f=QFT(b).
// b_f is in Fourier domain, a is not.
// Like Std.Arithmetic.FourierTDIncByLE, but without QFT.
operation FADD2(a : Qubit[], b_f : Qubit[]) : Unit is Ctl + Adj {
    for i in IndexRange(a) {
        Controlled PhaseGradient([a[i]], b_f[i...]);
    }
}

// Unoptimized Fourier Multiplier/Accumulator(ΦMAC) from §2.4.
// Computes b+=a*x, where b_f=QFT(b).
operation FMAC(a : BigInt, x : Qubit[], b_f : Qubit[]) : Unit is Ctl + Adj {
    let n = Length(x);
    Fact(Length(b_f) == 2 * n, "b must have 2n bits.");
    Fact(a < (1L <<< n), "a must have at most n bits.");

    for i in 0..n-1 {
        Controlled FADD([x[i]], (a <<< i, b_f));
    }
}

// Computes phase of the gate W_l (formula 16 in the paper).
function ComputeWPhase(a : BigInt, n : Int, l : Int) : BigInt {
    mutable phase : BigInt = 0L;
    for j in 0..Math.Min([l, n-1]) {
        set phase += (a % (1L <<< (l - j + 1))) <<< j;
    }
    return phase;
}

// Optimized controlled Fourier Multiplier/Accumulator(ΦMAC) from §3.
// Computes b+=c*a*x, where b_f=QFT(b).
operation ControlledFMAC(c : Qubit, a : BigInt, x : Qubit[], b_f : Qubit[]) : Unit is Ctl + Adj {
    let n = Length(x);
    Fact(Length(b_f) == 2 * n, "b must have 2n bits.");
    Fact(a < (1L <<< n), "a must have at most n bits.");

    for j in 0..n-1 {
        for l in j..(2 * n)-1 {
            let phase : BigInt = (a % (1L <<< (l-j + 1)));
            Controlled R1Precise([x[j]], (phase, l + 1 - j, b_f[l]));
        }
    }

    for j in 0..n-1 {
        CNOT(c, x[j]);
    }

    for j in 0..n-1 {
        for l in j..(2 * n)-1 {
            let phase : BigInt = -(a % (1L <<< (l-j + 1)));
            Controlled R1Precise([x[j]], (phase, l + 1 - j, b_f[l]));
        }
    }

    for j in 0..n-1 {
        CNOT(c, x[j]);
    }

    for l in 0..(2 * n)-1 {
        Controlled R1Precise([c], (ComputeWPhase(a, n, l), l + 1, b_f[l]));
    }
}

// Part of division algorithm that needs to be uncomputed.
operation DIV_Prepare(
    Reg0 : Qubit[],
    Reg1 : Qubit[],
    Reg2 : Qubit[],
    Reg4 : Qubit[],
    Reg5 : Qubit[],
    Reg6 : Qubit[],
    Aqbit : Qubit,
    d : BigInt,
    type : Int,
) : Unit is Ctl + Adj {
    // Initialization steps (§4.2, lines 1, 2, 3, of Algorithm).
    let n = Length(Reg2);
    let l : Int = 1 + Utils.FloorLog2(d);
    Fact(1L <<< (l-1) <= d, "2^(l-1)<=d");
    Fact(d < 1L <<< l, "d<2^l");
    let m1 : BigInt = ((1L <<< n) * ((1L <<< l)-d)-1L) / d;
    let d_norm : BigInt = d <<< (n-l);
    let d_c : BigInt = d_norm - (1L <<< n);

    // Computation of n2, n10, n1 (§4.2, lines 4, 5, 6 of Algorithm).
    ApplyQFT(Reg4);
    ApplyQFT(Reg6);
    if (type == 2) {
        FADD2(Reg5[0..n-l-1] + Reg0[0..l-1], Reg4);   // Reg4+=SLL(Reg0,n-l).
    }
    FADD2(Reg5[0..n-l-1] + Reg1[0..l-1], Reg6);   // Reg6+=SLL(Reg1,n-l).
    FADD2(Reg1[l..n-1] + Reg5[n-l..n-1], Reg4);   // Reg4+=SRL(Reg1,l).
    Adjoint ApplyQFT(Reg6);
    CNOT(Reg6[n-1], Aqbit);
    Controlled FADD([Aqbit], (1L, Reg4));
    // Here Reg4=QFT(n1+n2), Reg6=n10, Aqbit=n1.

    // Computation of nadj (§4.2, line 7 of Algorithm).
    within {
        ApplyQFT(Reg6);
    } apply {
        Controlled FADD([Aqbit], (d_c, Reg6));
    }
    Adjoint ApplyQFT(Reg4);
    // Here Reg4=n1+n2, Reg6 = nadj.

    // Computation of q1 (§4.2, line 8 of Algorithm).
    within {
        ApplyQFT(Reg6 + Reg5);
    } apply {
        FMAC(m1, Reg4, Reg6 + Reg5);
    }
    // Here (Reg6+Reg5) = nadj+m1*(n2+n1).
    Utils.ParallelCNOT(Reg5, Reg2);
    within {
        ApplyQFT(Reg2);
    } apply {
        FADD2(Reg4, Reg2);
        Controlled FADD([Aqbit], (-1L, Reg2));
    }
    // Here Reg2=q1.
}

// Division by constant d.
// (Reg1+Reg0) constains 2n-qubit dividend z.
// In the end, Reg0=0, Reg1=(z%d), Reg2=z/d.
operation GMFDIV(Reg0 : Qubit[], Reg1 : Qubit[], Reg2 : Qubit[], d : BigInt, type : Int) : Unit is Ctl + Adj {
    let n = Length(Reg0);
    Fact(Length(Reg1) == n, "Size mismatch.");
    Fact(Length(Reg2) == n, "Size mismatch.");
    Fact(d > 0L, "d must be positive.");
    Fact(d < (1L <<< n), "d must have size at most n bits.");
    use Reg3 = Qubit[n];
    use Reg4 = Qubit[n];
    use Reg5 = Qubit[n];
    use Reg6 = Qubit[n];
    use Aqbit = Qubit();

    DIV_Prepare(Reg0, Reg1, Reg2, Reg4, Reg5, Reg6, Aqbit, d, type);
    Utils.ParallelCNOT(Reg2, Reg3);

    // Computation of dr (§4.2, line 9 of Algorithm).
    within {
        ApplyQFT(Reg1 + Reg0);
    } apply {
        FMAC(-d, Reg2, Reg1 + Reg0);
        FADD(-d, Reg1 + Reg0);
    }
    // Here (Reg1+Reg0)=dr.

    // Computation of the quotient q (§4.2, line 10 of Algorithm).
    within {
        ApplyQFT(Reg2);
        X(Reg0[n-1]);
    } apply {
        Controlled FADD([Reg0[n-1]], (1L, Reg2));
    }
    // Here Reg2=q.

    // Computation of the remainder r (§4.2, line 11 of Algorithm).
    within {
        ApplyQFT(Reg1 + Reg0);
    } apply {
        FADD(d, Reg1 + Reg0);
        FMAC(d, Reg3, Reg1 + Reg0);
    }

    // Ancilla Restoration (§4.3).
    Adjoint DIV_Prepare(Reg0, Reg1, Reg3, Reg4, Reg5, Reg6, Aqbit, d, type);

    // Computation of the remainder r (second part).
    within {
        ApplyQFT(Reg1 + Reg0);
    } apply {
        FMAC(-d, Reg2, Reg1 + Reg0);
    }
    // Here (Reg1+Reg0)=r.
}

// Division by constant.
// Computes (z, q):=(z%d, z/d).
// z is n-qubit dividend; d is constant n-bit divisor; 1<=d<2^n.
// q has n qubits and must be prepared in zero state.
operation GMFDIV1(z : Qubit[], d : BigInt, q : Qubit[]) : Unit is Ctl + Adj {
    let n = Length(q);
    use Reg0 = Qubit[n];
    GMFDIV(Reg0, z, q, d, 1);
}

// Division by constant (special case for 2n-qubit dividend).
// Computes (z, q):=(z%d, z/d).
// z is 2n-qubit dividend; d is constant n-bit divisor; 1<=d<2^n.
// q has n qubits and must be prepared in zero state.
// It must be guaranteed that z/d < 2^n.
operation GMFDIV2(z : Qubit[], d : BigInt, q : Qubit[]) : Unit is Ctl + Adj {
    let n = Length(q);
    Fact(Length(z) == 2 * n, "Size mismatch.");
    GMFDIV(z[n..2 * n-1], z[0..n-1], q, d, 2);
}

// Optimized controlled modular multiplier/accumulator (ΦMAC_MOD1, §5.2).
// Computes ans := (a*y)%N if c=1, does nothing if c=0.
// ans must have n qubits and be prepared in zero state.
// Doesn't change y.
// It must be guaranteed that N<2^n; (a*y)/N < 2^n.
operation FMAC_MOD2(
    c : Qubit,
    y : Qubit[],
    ans : Qubit[],
    a : BigInt,
    N : BigInt
) : Unit is Ctl + Adj {
    let n = Length(y);
    Fact(0L <= a and a < (1L <<< n), "a out of bounds.");
    Fact(1L <= N and N < (1L <<< n), "N out of bounds.");
    Fact(Length(ans) == n, "Size mismatch.");
    use anc1 = Qubit[n];
    use anc2 = Qubit[n];
    use anc3 = Qubit[n];

    within {
        ApplyQFT(ans + anc1);
    } apply {
        ControlledFMAC(c, a, y, ans + anc1);
    }
    GMFDIV2(ans + anc1, N, anc3);
    // Here anc1=0, ans=(c*a*y)%N, anc3=(c*a*y)/N.

    ParallelCNOT(ans, anc2);

    Adjoint GMFDIV2(anc2 + anc1, N, anc3);
    within {
        ApplyQFT(anc2 + anc1);
    } apply {
        Adjoint ControlledFMAC(c, a, y, anc2 + anc1);
    }
}

// Modular exponentiation. (ΦMUL MOD2, §6).
// Computes y:=(a*y)%N ig c=1. Does nothing if c=0.
// It must be guaranteed that N<2^n; (a*y)/N < 2^n; a is co-prime with N.
operation FMUL_MOD2(c : Qubit, y : Qubit[], a : BigInt, N : BigInt) : Unit is Ctl + Adj {
    Fact(Math.IsCoprimeL(a, N), "a and N must be coprime.");
    let (a_inv, unused_v) = Math.ExtendedGreatestCommonDivisorL(a, N);
    let a_inv : BigInt = ((a_inv % N) + N) % N;
    Fact(1L <= a_inv and a_inv < N, "a_inv out of bound");
    Fact((a * a_inv) % N == 1L, "a_inv is computed incorrectly");

    let n = Length(y);
    use ans = Qubit[n];

    FMAC_MOD2(c, y, ans, a, N);
    for i in 0..n-1 {
        Controlled SWAP([c], (y[i], ans[i]));
    }
    Adjoint FMAC_MOD2(c, y, ans, a_inv, N);
}

// Computes y=(a^x)%N.
// y must be prepared in zero state.
// Doesn't change x.
// Sizes of x and y don't necessarily have to match.
// a must be co-prime with N.
operation EXP_MOD(x : Qubit[], y : Qubit[], a : BigInt, N : BigInt) : Unit is Ctl {
    mutable a_cur : BigInt = a;
    X(y[0]); // y:=1.
    for i in 0..Length(x)-1 {
        FMUL_MOD2(x[i], y, a_cur, N);
        set a_cur = (a_cur * a_cur) % N;
    }
}

export FMAC, GMFDIV1, GMFDIV2, FMAC_MOD2, FMUL_MOD2, EXP_MOD;