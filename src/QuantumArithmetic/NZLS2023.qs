/// Implementation of the multiplier presented in paper:
///   Quantum Circuit Design for Integer Multiplication Based on Schönhage-Strassen Algorithm
///   Junhong Nie, Qinlin Zhu, Meng Li, Xiaoming Sun, 2023.
///   https://ieeexplore.ieee.org/abstract/document/10138719
/// All numbers are unsigned integers, little-endian.
/// The paper uses adder from Cuccaro's 2004 paper (implemented in CDKM2004.qs).

import Std.Diagnostics.Fact;
import QuantumArithmetic.CDKM2004;

// Computes C=A*B (mod 2^n). C must be prepared in zero state.
//
// This is a "standard texbook algorithm" used as recursion base case, to
// multiply numbers with n<=16 bits.
operation MultiplyTextbook(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(Length(C) == 2 * n, "Register sizes must match.");
    for i in 0..n-1 {
        Controlled CDKM2004.AddWithCarry([A[i]], (B, C[i..i+n-1], C[i+n]));
    }
}

export MultiplyTextbook;