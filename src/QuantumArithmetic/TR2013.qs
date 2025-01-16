///   Implementation of 
///   Design of efficient reversible logic-based binary and BCD adder circuits
///   Himanshu Thapliyal and Nagarajan Ranganathan, 2013.
///   Note: Orginally published in ACM Journal on Emerging Technologies in Computing Systems in 2013
///     even though arXiv shows a date of 2017.
///   https://doi.org/10.1145/2491682

import Std.Diagnostics.Fact;

operation V(target : Qubit) : Unit is Adj + Ctl {
    Rx(Std.Math.PI() * 0.5, target);
}

operation TR(A : Qubit, B : Qubit, C : Qubit) : Unit is Adj + Ctl {
    Controlled Adjoint V([B], C);
    CNOT(A, B);
    Controlled V([A], C);
    Controlled V([B], C);
}

operation Peres(A : Qubit, B : Qubit, C: Qubit) : Unit is Adj + Ctl {
    Controlled Adjoint V([A], C);
    Controlled Adjoint V([B], C);
    CNOT(A, B);
    Controlled V([B], C);
}

operation oldToffoli(A : Qubit, B : Qubit, C :Qubit) : Unit is Adj + Ctl {
    Controlled V([A], C);
    CNOT(B, A);
    Controlled V([B], C);
    Controlled Adjoint V([A], C);
    CNOT(B, A);
}

operation AddwithZ(A: Qubit [], B: Qubit [], Z: Qubit) : Unit is Adj + Ctl {
    let n = Length(A);
    let bigA = A + [Z];

    // step 1
    for i in 1..n-1{
        CNOT(bigA[i], B[i]);
    }

    // step 2
    for i in n-1..-1..1{
        CNOT(bigA[i], bigA[i+1]);
    }

    // step 3
    for i in 0..n-2{
        oldToffoli(B[i], bigA[i], bigA[i+1]);
    }

    // step 4
    for i in n-1..-1..0{
        Peres(bigA[i], B[i], bigA[i+1]);
    }

    // step 5
    for i in 1..n-2{
        CNOT(bigA[i], bigA[i+1]);
    }

    // step 6
    for i in n-1..-1..1{
        CNOT(bigA[i], B[i]);
    }
}

operation AddwithZandCarry(A: Qubit [], B: Qubit [], Z: Qubit, carry: Qubit) : Unit is Adj + Ctl {
    let n = Length(A);
    let bigA = A + [Z];

    // step 1
    for i in 0..n-1{
        CNOT(bigA[i], B[i]);
    }

    // step 2
    CNOT(bigA[0], carry);
    for i in 0..n-2{
        CNOT(bigA[i+1], bigA[i]);
    }
    CNOT(bigA[n-1], bigA[n]);

    // step 3
    oldToffoli(carry, B[0], bigA[0]);
    for i in 1..n-2 {
        oldToffoli(bigA[i-1], B[i], bigA[i]);
    }
    if n > 1 {
        Peres(bigA[n-2], B[n-1], bigA[n]);
    }
    for i in 0..n-2{
        X(B[i]);
    }

    // step 4
    for i in n-2..-1..1{
        TR(bigA[i-1], B[i], bigA[i]);
    }
    TR(carry, B[0], bigA[0]);
    for i in 0..n-2{
        X(B[i]);
    }

    // step 5
    for i in n-2..-1..0{
        CNOT(bigA[i+1], bigA[i]);
    }
    CNOT(bigA[0], carry);

    // step 6
    for i in n-1..-1..0{
        CNOT(bigA[i], B[i]);
    }



}

// Computes B:=(A+B)%(2^n).
operation Add(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    if n >=2 {
        AddwithZ(A[0..n-2], B[0..n-2], B[n-1]);
    }
    CNOT(A[n-1], B[n-1]);
}

// Computes B:=(A+B)%(2^n) with an carry in
// note that the carry in remains as is on output and is NOT a carry out
operation AddWithCarry(A: Qubit[], B: Qubit[], carry: Qubit) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");
    Fact(n > 2, "Algorithm requires n > 2.");

    AddwithZandCarry(A[0..n-2], B[0..n-2], B[n-1], carry);
    CNOT(A[n-1], B[n-1]);

}

export Add, AddWithCarry;