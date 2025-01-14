/// Implementation of a restoring division algorithms presented in the paper:
///   Quantum Division Circuit Based on Restoring Division Algorithm, https://ieeexplore.ieee.org/document/5945378/

import Std.Diagnostics.Fact;
import QuantumArithmetic.Xin2018.CompareLess;
import QuantumArithmetic.TMVH2019.Subtract;

// recursion
operation prog(a: Qubit[], b: Qubit[], s: Qubit, ctr: Qubit, i: Int) : Unit is Adj + Ctl {
    let n = Length(a);
    if (i == n - 1) {
        within {
            CCNOT(a[i-1], b[i-1], a[i])
        } apply {
            CCNOT(a[i], ctr, s);
        }
    } else {
        within {
            CCNOT(a[i-1], b[i-1], a[i]);
        } apply {
            prog(a, b, s, ctr, i + 1);
            CCNOT(a[i], ctr, b[i]);
        }
    }
}

operation Subtract_NotEqualBit(a : Qubit[], b : Qubit[], s2: Qubit, ctr: Qubit) : Unit is Adj + Ctl {
    let n = Length(a);
    let m = Length(b);
    Fact(m + 1 == n, "Subtracter size must be one less than the minuend size.");
    let s = b[0..m-1] + [s2];
    for i in 0..n-1 {
        CNOT(ctr, a[i]);
    }
    within {
        for i in 1..m-1 {
            CNOT(a[i], b[i]);
        }
        for i in m-1..-1..1 {
            CNOT(a[i], a[i+1]);
        }
    } apply {
        prog(a, b, s2, ctr, 1);
        CCNOT(a[0], ctr, b[0]);
    }
    for i in 0..n-1 {
        CNOT(ctr, s[i]);
    }
    for i in 0..n-1 {
        CNOT(ctr, a[i]);
    }
}


/// Computes a,b,c:=(a%b,b,a//b).
///
/// Constraints:
///  * a,b,c must have the same number of qubits n.
///  * 0 <= a < 2^n.
///  * 0 < b < 2^(n-1).
///  * c must be initialized to zeros.
operation Divide(D : Qubit[], Q : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(D);
    let m = Length(Q);
    use acc = Qubit();
    let cfg = new QuantumArithmetic.TMVH2019.Config { Adder = Std.Arithmetic.RippleCarryTTKIncByLE };

    for i in 0..n-m {
        // compare D[n-1-i...n-m-i] with Q[m-1...0]
        CompareLess(D[n-m-i..n-1-i], Q[0..m-1], acc);
        // if acc = 0, D >= Q, compute D = D[n-1-i...n-m-i] - Q[m-1...0] + D[n-m-1...0]
        Controlled Subtract([acc], (D[n-m-i..n-1-i], Q[0..m-1], cfg));
        // if acc = 1, D < Q, D = D[n-1-i...n-m-i-1] - Q[m-1...0] + D[n-m-2...0] 

    }
}
export Divide;
