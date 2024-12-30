/// Original addition algorithms.

import Std.Diagnostics.Fact;
import QuantumArithmetic.JHHA2016;
import QuantumArithmetic.Utils;

/// Computes carries array given A, B and C[0].
/// By definition, C[i+1]=MAJ(A[i], B[i], C[i]).
/// Answer is C[1..n], which must be prepared in 0 state.
operation ComputeCarries(A : Qubit[], B : Qubit[], C : Qubit[]): Unit is Adj + Ctl  {
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

/// Computes Carry ⊕= (A+B)/2^n.
operation ComputeOverflowBit(A : Qubit[], B : Qubit[], Carry : Qubit): Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    use C = Qubit();
    within {
        for i in 0..n-1 {
            Std.Arithmetic.MAJ(A[i], B[i], C);
        }
    } apply {
        CNOT(C, Carry);
    }
}

/// Computes C:=(A+B+(A+B)/2^n)%(2^n) which is ≡ A+B (mod 2^n-1).
operation AddMod2NMinus1OutOfPlace(A : Qubit[], B : Qubit[], C : Qubit[]): Unit is Adj + Ctl {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    Fact(Length(C) == n, "Size mismatch.");
    ComputeOverflowBit(A, B, C[0]);
    ComputeCarries(A[0..n-2], B[0..n-2], C);
    Utils.ParallelCNOT(A, C);
    Utils.ParallelCNOT(B, C);
}

/// Computes B:=(A+B+(A+B)/2^n)%(2^n) which is ≡ A+B (mod 2^n-1).
/// This is needed for NZLS2023.
/// WARNING: this is incorrect for superposition states.
/// TODO: implement this correctly, as described in DKRS2004.
operation AddMod2NMinus1InPlace(A : Qubit[], B : Qubit[]) : Unit {
    let n = Length(A);
    Fact(Length(B) == n, "Size mismatch.");
    use Cin = Qubit();
    ComputeOverflowBit(A, B, Cin);
    JHHA2016.AddWithInputCarry(B, Cin, A);
    Reset(Cin);
}