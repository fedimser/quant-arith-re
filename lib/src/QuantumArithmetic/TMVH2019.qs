import QuantumArithmetic.Utils.ParallelX;
/// Implementation of 2 division algorithms presented in the paper:
///   Quantum Circuit Designs of Integer Division Optimizing T-count and T-depth,
///   Thapliyal, Munoz-Coreas, Varun, Humble, 2019, https://arxiv.org/pdf/1809.09732.
/// All numbers are little-endian.

import Std.Diagnostics.Fact;


/// Allows to specify which adder to use.
struct Config {
    Adder : (Qubit[], Qubit[]) => Unit is Adj + Ctl,
}

operation Add(xs : Qubit[], ys : Qubit[], cfg : Config) : Unit is Adj + Ctl {
    cfg.Adder(xs, ys);
}

// Computes ys+=xs if ctrl=1, does nothing if ctrl=0.
operation CtrlAdd(ctrl : Qubit, xs : Qubit[], ys : Qubit[], cfg : Config) : Unit is Adj + Ctl {
    Controlled Add([ctrl], (xs, ys, cfg));
}

/// Computes ys -= xs by reducing problem to addition and using the Ripple-Carry adder.
/// Ref: Thapliyal, 2016, https://link.springer.com/chapter/10.1007/978-3-662-50412-3_2
operation Subtract(xs : Qubit[], ys : Qubit[], cfg : Config) : Unit is Adj + Ctl {
    ParallelX(ys);
    Add(xs, ys, cfg);
    ParallelX(ys);
}

// Computes ys-=xs if ctrl=1, and ys+=xs if ctrl=0.
operation AddSub(ctrl : Qubit, xs : Qubit[], ys : Qubit[], cfg : Config) : Unit is Adj + Ctl {
    let ysLen = Length(ys);
    for i in 0..ysLen-1 {
        CNOT(ctrl, ys[i]);
    }
    Add(xs, ys, cfg);
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
operation Divide_Restoring(a : Qubit[], b : Qubit[], c : Qubit[], cfg : Config) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes must match.");
    Fact(Length(c) == n, "Registers sizes must match.");
    let R = c;
    let Q = a;

    for i in 1..n {
        let Y = Q[n-i..n-1] + R[0..n-1-i];
        Subtract(b, Y, cfg);
        CX(Y[n-1], R[n-i]);
        CtrlAdd(R[n-i], b, Y, cfg);
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
operation Divide_NonRestoring(a : Qubit[], b : Qubit[], c : Qubit[], cfg : Config) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes are incompatible.");
    Fact(Length(c) == n-1, "Registers sizes are incompatible.");
    let R = a[0..n-2];
    let Q = [a[n-1]] + c;

    Subtract(b, Q, cfg);
    for i in 1..n-1 {
        X(Q[n-i]);
        let Y = R[n-1-i..n-2] + Q[0..n-1-i];
        AddSub(Q[n-i], b, Y, cfg);
    }
    CtrlAdd(Q[0], b[0..n-2], R, cfg);
    X(Q[0]);
}

/// Computes (a; b; c) := (a%b; b, a/b).
/// Register sizes must be (n, n-1, n). c must be prepared in zero state.
/// Default divider, recommended for general-purpose usage.
/// Interface changed from the paper, to make usage more convenient.
/// Any input value of a and b is valid.
operation Divide(a : Qubit[], b : Qubit[], c : Qubit[]) : Unit is Adj + Ctl {
    let config = new Config { Adder = Std.Arithmetic.RippleCarryCGIncByLE };
    let n = Length(a);
    Fact(Length(b) == n-1, "Registers sizes are incompatible.");
    Fact(Length(c) == n, "Registers sizes are incompatible.");
    Divide_NonRestoring(a, b + [c[0]], c[1..n-1], config);
    SWAP(a[n-1], c[0]);
}

export Divide_Restoring, Divide_NonRestoring, Divide;
