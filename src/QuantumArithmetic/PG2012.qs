/// Implementation of operations presented in paper:
///   Fast quantum modular exponentiation architecture for Shor's factoring algorithm
///   Archimedes Pavlidis and Dimitris Gizopoulos, 2012.
///   https://arxiv.org/pdf/1207.0511
/// All numbers are unsigned integer, little-endian.

import Std.Convert.*;
import Std.Diagnostics.Fact;
import Std.Math;

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
// Computes b+=a*x, where b_f=QFT(b).
operation FADD(a : BigInt, b_f : Qubit[]) : Unit is Ctl {
    let n = Length(b_f);
    for j in 0..n-1 {
        let phase = 2L * (a % (1L <<< (j + 1)));
        R1Precise(phase, j + 1, b_f[j]);
    }
}

// Unoptimized Fourier Multiplier/Accumulator(ΦMAC) from §2.4.
// Computes b+=c*a*x, where b_f=QFT(b).
operation FMAC_Unoptimized(c : Qubit, a : BigInt, x : Qubit[], b_f : Qubit[]) : Unit is Ctl {
    let n = Length(x);
    Fact(Length(b_f) == 2 * n, "b must have 2n bits.");
    Fact(a >= 0L, "a cannot be negative.");
    Fact(a < (1L <<< n), "a must have at most n bits.");

    for i in 0..n-1 {
        Controlled FADD([c, x[i]], (a <<< i, b_f));
    }
}

// Optimized Fourier Multiplier/Accumulator(ΦMAC) from §3.
// Computes b+=c*a*x, where b_f=QFT(b).
operation FMAC(c : Qubit, a : BigInt, x : Qubit[], b_f : Qubit[]) : Unit is Ctl {
    let n = Length(x);
    Fact(Length(b_f) == 2 * n, "b must have 2n bits.");
    Fact(a >= 0L, "a cannot be negative.");
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
        mutable phase : BigInt = 0L;
        for j in 0..Math.Min([l, n-1]) {
            set phase += (a % (1L <<< (l - j + 1))) <<< j;
        }
        Controlled R1Precise([c], (phase, l + 1, b_f[l]));
    }
}


export FMAC;
