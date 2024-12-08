/// Implementation of operations presented in paper:
///   Fast quantum modular exponentiation architecture for Shor's factoring algorithm
///   Archimedes Pavlidis and Dimitris Gizopoulos, 2012.
///   https://arxiv.org/pdf/1207.0511
/// All numbers are unsigned integer, little-endian.

import Std.Convert.BigIntAsBoolArray;
import Std.Convert.IntAsBigInt;
import Std.Diagnostics.Fact;

// Computes b += a*x, where b_f=QFT(b).
operation FADD(a : BigInt, b_f : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(b_f);
    let a_bits = BigIntAsBoolArray(a, n);
    for j in 0..n-1 {
        for k in 1..j + 1 {
            if (a_bits[j + 1-k]) {
                R1Frac(2, k, b_f[j]);
            }
        }
    }
}

// Unoptimized Fourier Multiplier/Accumulator(ΦMAC) from §2.4.
// Computes b += c*a*x, where b_f=QFT(b).
operation FMAC_Unoptimized(c : Qubit, a : BigInt, x : Qubit[], b_f : Qubit[]) : Unit is Ctl {
    let n = Length(x);
    Fact(Length(b_f) == 2 * n, "b must have 2n bits.");
    Fact(a >= 0L, "a cannot be negative.");
    Fact(a < (1L <<< n), "a must have at most n bits.");

    mutable k : BigInt = a;
    for i in 0..n-1 {
        Controlled FADD([c, x[i]], (k, b_f));
        set k = k * 2L;
    }
}



export FMAC_Unoptimized;
