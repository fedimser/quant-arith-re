/// Implementation of 2 division algorithms presented in the paper:
///   Quantum Circuit Designs of Integer Division Optimizing T-count and T-depth,
///   Thapliyal, Munoz-Coreas, Varun, Humble, 2019, https://arxiv.org/pdf/1809.09732.
/// All numbers are little-endian.

import Std.Diagnostics.Fact;

operation Add(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    Std.Arithmetic.RippleCarryTTKIncByLE(xs, ys);
}

// Computes ys+=xs if ctrl=1, does nothing if ctrl=0.
operation CtrlAdd(ctrl : Qubit, xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    Controlled Add([ctrl], (xs, ys));
}

/// Computes ys -= xs by reducing problem to addition and using the Ripple-Carry adder.
/// Ref: Thapliyal, 2016, https://link.springer.com/chapter/10.1007/978-3-662-50412-3_2
operation Subtract(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    let ysLen = Length(ys);
    for i in 0..ysLen-1 {
        X(ys[i]);
    }
    Add(xs, ys);
    for i in 0..ysLen-1 {
        X(ys[i]);
    }
}

// Computes ys-=xs if ctrl=1, and ys+=xs if ctrl=0.
operation AddSub(ctrl : Qubit, xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    let ysLen = Length(ys);
    for i in 0..ysLen-1 {
        CNOT(ctrl, ys[i]);
    }
    Add(xs, ys);
    for i in 0..ysLen-1 {
        CNOT(ctrl, ys[i]);
    }
}

/// Computes a,b,c:=(a%b,b,a/b).
///
/// Constraints:
///  * a,b,c must have the same number of qubits n.
///  * 0 <= a < 2^n.
///  * 0 < b < 2^(n-1).
///  * c must be initialized to zeros.
operation Divide_Restoring(a : Qubit[], b : Qubit[], c : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes must match.");
    Fact(Length(c) == n, "Registers sizes must match.");
    let R = c;
    let Q = a;

    for i in 1..n {
        let Y = Q[n-i..n-1] + R[0..n-1-i];
        Subtract(b, Y);
        CX(Y[n-1], R[n-i]);
        CtrlAdd(R[n-i], b, Y);
        X(R[n-i]);
    }
}

/// Computes (a[0..n-2]; [a[n-1]]+c; b) := (a%b; a/b; b).
///
/// Constraints:
///  * a and b must have n qubits, c must have size n-1 qubits.
///  * 0 <= a < 2^n.
///  * 0 < b < 2^(n-1).
///  * c must be initialized to zeros.
operation Divide_NonRestoring(a : Qubit[], b : Qubit[], c : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes are incompatible.");
    Fact(Length(c) == n-1, "Registers sizes are incompatible.");
    let R = a[0..n-2];
    let Q = [a[n-1]] + c;

    Subtract(b, Q);
    for i in 1..n-1 {
        X(Q[n-i]);
        let Y = R[n-1-i..n-2] + Q[0..n-1-i];
        AddSub(Q[n-i], b, Y);
    }
    CtrlAdd(Q[0], b[0..n-2], R);
    X(Q[0]);
}

export Divide_Restoring, Divide_NonRestoring;
