import Std.Arrays.ForEach;
/// Implementation of the multiplier presented in paper:
///   Quantum Circuit Design for Integer Multiplication Based on Schönhage-Strassen Algorithm
///   Junhong Nie, Qinlin Zhu, Meng Li, Xiaoming Sun, 2023.
///   https://ieeexplore.ieee.org/abstract/document/10138719
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;
import QuantumArithmetic.CDKM2004;
import QuantumArithmetic.Utils;

// Computes C=A*B (mod 2^n). C must be prepared in zero state.
//
// This is a "standard texbook algorithm" used as recursion base case, to
// multiply numbers with n<=16 bits.
// The paper instructs to use here the adder from Cuccaro-2004 paper, which is
// implemented in CDKM2004.qs
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
// The paper instructs to implement this by rearranging qubits, but that is not
// possible in Adjoint Q# operation. We implement it by SWAPs, hoping that Q# 
// optimizing compiler will replace explicit SWAPs with renaming qubits.
// This operation is intentionally not marked Controlled, to guarantee that 
// SWAPs can be eliminated.
// TODO: optimize so it takes O(len) SWAP gates.
operation CyclicShiftRight(A : Qubit[], r : Int) : Unit is Adj {
    let len = Length(A); // len = 2n'.
    Fact(len % 2 == 0, "Register length must be even");
    let r1 = (r % len + r) % len;
    for i in 1..r {
        Utils.RotateRight(A);
    }
}

// Computes B+=A.
operation AddDKRSInPlace(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    Std.Arithmetic.IncByLEUsingAddLE(
        Std.Arithmetic.LookAheadDKRSAddLE,
        Std.Arithmetic.LookAheadDKRSAddLE,
        A,
        B
    );
}

// Buttefly operation from §III-C-1, Fig.3.
// Computes (A,B) := (A+B, A-B) modulo N=(2^n')+1.
// A and B are 2n'-bit numbers.
// The paper instructs to use here the adder from Draper-2004 paper, which is
// implemented in the Q# standard library.
operation Butterfly(A : Qubit[], B : Qubit[]) : Unit is Adj {
    let len = Length(A); // len = 2n'.
    Fact(Length(B) == len, "|B|=2n'");
    AddDKRSInPlace(B, A);
    for i in 0..len-1 {
        X(B[i]);
    }
    CyclicShiftRight(B, 1);
    AddDKRSInPlace(A, B);
}

// FFT circuit from §III-C-2, Fig.4.
// Computes X[m]:=sum(X[t]*g^(t*m) for t in 0..D-1) modulo N, where:
//   g = 2^g_pwr;
//   N = (2^n')+1;
//   X is sequence of D 2n'-bit integers (dimension of X is (D,2n')).
operation FFT(X : Qubit[][], g_pwr : Int) : Unit is Adj {
    // g = 2^g_pwr.
    let D = Length(X);
    if (D==4) {
        AddDKRSInPlace(X[0], X[1]);
    }
    if (D > 1) {      
        Message($"D={D}");
        Fact(D % 2 == 0, "D must be power of 2.");
        let half_D = D / 2;
        let g_sqr_pwr = (2 * g_pwr) % Length(X[0]);
        FFT(X[0..2..D-2], g_sqr_pwr);
        FFT(X[1..2..D-1], g_sqr_pwr);
        for i in 0..half_D-1 {
            CyclicShiftRight(X[2 * i + 1], g_pwr*i); // x g^i.
        }
        for i in 0..half_D-1 {
            Butterfly(X[2*i], X[2*i+1]);
        }
        // TODO: Rearrange.
    }
}

export MultiplyTextbook;