import Std.Diagnostics.DumpRegister;
/// Implementation of a restoring division algorithms presented in the paper:
///   Quantum Division Circuit Based on Restoring Division Algorithm, https://ieeexplore.ieee.org/document/5945378/

import Std.Diagnostics.Fact;
import QuantumArithmetic.Xin2018.CompareLess;
import QuantumArithmetic.TMVH2019.Subtract;
// ys -= xs
operation Subtract_NotEqualBit(x : Qubit[], y : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(y);
    let m = Length(x);
    // add qubits in front of b
    use s = Qubit[n-m];
    let b = x + s;
    Subtract_EqualBit(b, y);
}

//  Computes ys -= xs
operation Subtract_EqualBit(x : Qubit[], y : Qubit[]) : Unit is Adj + Ctl {
    let cfg = new QuantumArithmetic.TMVH2019.Config { Adder = Std.Arithmetic.RippleCarryTTKIncByLE };
    Fact(Length(y) == Length(x), "Registers sizes must match.");
    Subtract(x, y, cfg);
}

///
/// Constraints:
///  * a,b,c must have the same number of qubits n.
///  * 0 <= a < 2^n.
///  * 0 < b < 2^(n-1).
///  * c must be initialized to zeros.
operation Divide(D : Qubit[], Q : Qubit[], S: Qubit[]) : Unit {
    let n = Length(D);
    let m = Length(Q);
    let s_len = Length(S); // problem here
    Fact(n-m+1 == s_len, "Quotient sizes must match.");

    use compare_result = Qubit[n-m+1];
    use acc = Qubit[n-m+1];
    for i in 0..n-m {
        CompareLess(D[n-m-i..n-1-i], Q[0..m-1], compare_result[i]);
        DumpRegister(D[n-m-i..n-1-i]);
        DumpRegister(Q[0..m-1]);
        DumpRegister([compare_result[i]]);
        X(compare_result[i]);
        CNOT(compare_result[i], S[n-m-i]);
        Controlled Subtract_EqualBit([compare_result[i]], (Q[0..m-1],D[n-m-i..n-1-i]));
        X(compare_result[i]);
        if (i != n-m) {
            CNOT(D[n-1-i], S[n-m-i-1]);
            // CCNOT(compare_result[i], D[n-1-i], S[n-m-i-1]);
            CCNOT(compare_result[i], D[n-1-i], acc[i]);
            // DumpRegister([S[n-m-i-1]]);
            Controlled Subtract_NotEqualBit([acc[i]], (Q[0..m-1], D[n-m-i-1..n-1-i]));
        }
        Reset(compare_result[i]);
        Reset(acc[i]);
    }
}
export Divide;
