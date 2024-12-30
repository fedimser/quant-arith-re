/// Implementation of the multiplier presented in paper:
///   Quantum Circuit Design for Integer Multiplication Based on Schönhage-Strassen Algorithm
///   Junhong Nie, Qinlin Zhu, Meng Li, Xiaoming Sun, 2023.
///   https://ieeexplore.ieee.org/abstract/document/10138719
/// All numbers are unsigned integers, little-endian.
///
/// WARNING! This code is not finished.
/// It's blocked on reversible implementation of addition mod 2^n-1.

import Std.Diagnostics.Fact;
import QuantumArithmetic.AdditionOrig;
import QuantumArithmetic.CDKM2004;
import QuantumArithmetic.Utils;

/// Computes C=A*B (mod 2^n). C must be prepared in zero state.
///
/// This is a "standard texbook algorithm" used as recursion base case, to
/// multiply numbers with n<=16 bits.
/// The paper instructs to use here the adder from Cuccaro-2004 paper, which is
/// implemented in CDKM2004.qs.
/// WARNING. This algorithm is correct, but very inefficient, as it contains
/// triple-controlled gates.
/// TODO: use better Shift-And-Add multiplier as base case (maybe JHHA2016 or
/// MCT2017).
operation MultiplyTextbook(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(Length(C) == 2 * n, "Register sizes must match.");
    for i in 0..n-1 {
        Controlled CDKM2004.AddWithCarry([A[i]], (B, C[i..i + n-1], C[i + n]));
    }
}

// Multiplies 2n'-bit number by 2^r modulo (2^n')+1.
// As §III-B shows, this is equivalent to right cyclic shift by r.
// r can be negative.
operation CyclicShiftRight(A : Qubit[], r : Int) : Unit is Adj {
    let len = Length(A); // len = 2n'.
    Fact(len % 2 == 0, "Register length must be even");
    let r1 = (r % len + len) % len;
    let perm = Utils.RangeAsIntArray(len-r1..len-1) + Utils.RangeAsIntArray(0..len-r1-1);
    Utils.ApplyPermutation(A, perm);
}

// Buttefly operation from §III-C-1, Fig.3.
// Computes (A,B) := (A+B, A-B) modulo N=(2^n')+1.
// A and B are 2n'-bit numbers.
// The paper instructs to use here the adder from Draper-2004 paper, which is
// implemented in the Q# standard library.
operation Butterfly(A : Qubit[], B : Qubit[]) : Unit {
    let len = Length(A); // len = 2n'.
    Fact(Length(B) == len, "|B|=2n'");
    AdditionOrig.AddMod2NMinus1InPlace(B, A);
    for i in 0..len-1 {
        X(B[i]);
    }
    CyclicShiftRight(B, 1);
    AdditionOrig.AddMod2NMinus1InPlace(A, B);
}

// FFT circuit from §III-C-2, Fig.4.
// Computes X[m]:=sum(X[t]*g^(t*m) for t in 0..D-1) modulo N, where:
//   g = 2^g_pwr;
//   N = (2^n')+1;
//   X is sequence of D 2n'-bit integers (dimension of X is (D,2n')).
operation FFT(X : Qubit[][], g_pwr : Int) : Unit {
    // g = 2^g_pwr.
    let D = Length(X);
    if (D > 1) {
        Fact(D % 2 == 0, "D must be power of 2.");
        let half_D = D / 2;
        let len = Length(X[0]); // 2n'.
        let g_sqr_pwr = (2 * g_pwr) % len;
        FFT(X[0..2..D-2], g_sqr_pwr);
        FFT(X[1..2..D-1], g_sqr_pwr);
        for i in 0..half_D-1 {
            CyclicShiftRight(X[2 * i + 1], g_pwr * i); // x g^i.
        }
        for i in 0..half_D-1 {
            Butterfly(X[2 * i], X[2 * i + 1]);
        }

        // Reorder the result.
        let perm = Utils.RangeAsIntArray(0..2..D-2) + Utils.RangeAsIntArray(1..2..D-1);
        for bit_idx in 0..len-1 {
            let qs = Std.Arrays.MappedOverRange(i -> X[i][bit_idx], 0..D-1);
            Utils.ApplyPermutation(qs, perm);
        }
    }
}

export MultiplyTextbook;