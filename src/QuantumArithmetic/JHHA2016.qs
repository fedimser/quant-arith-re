/// Implementation of adder and multiplier presented in paper:
/// Ancilla-Input and Garbage-Output Optimized Design of a Reversible Quantum Integer Multiplier
/// Jayashree HV, Himanshu Thapliyal, Hamid R. Arabnia, V K Agrawal, 2016.
/// https://arxiv.org/abs/1608.01228

import Std.Diagnostics.Fact;

// Computes P+=Am*B[1..].
// B[0] must be prepared in zero state and is returned in zero state.
operation AddNop(P : Qubit[], B : Qubit[], Am : Qubit) : Unit is Adj + Ctl {
    let n = Length(B)-1;
    Fact(Length(P) == n + 1, "Register sizes must match.");

    for i in 0..n-1 {
        CCNOT(Am, B[i + 1], P[i]);
        Controlled SWAP([P[i]], (B[i], B[i + 1]));
    }
    CCNOT(Am, B[n], P[n]);
    for i in n-1..-1..0 {
        Controlled SWAP([P[i]], (B[i], B[i + 1]));
        CCNOT(Am, B[i], P[i]);
    }
}

// Rotates right bits of P.
operation RotateRight(P : Qubit[]) : Unit is Adj + Ctl {
    let k : Int = Length(P);
    let k1 : Int = k / 2;
    for i in 0..k1-1 {
        SWAP(P[i], P[k-1-i]);
    }
    for i in 0..k1-2 + (k % 2) {
        SWAP(P[i], P[k-2-i]);
    }
}

// Computes P+=A*B (mod 2^n).
operation Multiply(A : Qubit[], B : Qubit[], P : Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(Length(P) == 2 * n, "Register sizes must match.");
    use Zcin = Qubit();

    for i in 0..n-2 {
        AddNop(P[n-1..2 * n-1], [Zcin] + B, A[i]);
        RotateRight(P);
    }
    AddNop(P[n-1..2 * n-1], [Zcin] + B, A[n-1]);
}

/// Computes P+=(B+InputCarry) modulo 2^n.
/// Adapted from AddNop by removing control and output carry.
operation AddWithInputCarry(P : Qubit[], InputCarry : Qubit, B : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(B);
    Fact(Length(P) == n, "Register sizes must match.");
    let B1 = [InputCarry] + B;
    for i in 0..n-1 {
        CNOT(B1[i + 1], P[i]);
        Controlled SWAP([P[i]], (B1[i], B1[i + 1]));
    }
    for i in n-1..-1..0 {
        Controlled SWAP([P[i]], (B1[i], B1[i + 1]));
        CNOT(B1[i], P[i]);
    }
}

/// Computes B+=A modulo 2^n.
operation Add_Mod2N(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    use Carry = Qubit();
    AddWithInputCarry(B, Carry, A);
}

export Multiply, AddWithInputCarry, Add_Mod2N;