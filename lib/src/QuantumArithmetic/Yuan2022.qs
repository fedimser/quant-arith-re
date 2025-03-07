/// Implementation of a restoring division algorithms presented in the paper:
/// A novel fault-tolerant quantum divider and its simulation, https://ieeexplore.ieee.org/document/5945378/
import Std.Diagnostics.Fact;
import QuantumArithmetic.Xin2018.CompareLess;
import QuantumArithmetic.TMVH2019.Subtract;
// ys -= xs
operation Subtract_NotEqualBit(x : Qubit[], y : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(y);
    let m = Length(x);
    // add 1 qubit in front of b for carry
    use s = Qubit();
    let b = x + [s];
    Subtract_EqualBit(b, y[0..m]);
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
    let s_len = Length(S);
    Fact(n-m+1 == s_len, "Quotient sizes must match.");
    use compare_result = Qubit();
    use acc  =  Qubit();
    for i in 0..n-m {
        CompareLess(D[n-m-i..n-1-i ] , Q[0..m-1], compare_result);
        // if compare_r e sult = 0, D >= Q, compute D = D[n-1-i...n-m-i] - Q[m-1...0] + D[n-m-1...0]
        X(compare_result);
        CNOT(compare_result, S[n-m-i]);
        Controlled Subtract_EqualBit([compare_result], (Q[0..m-1],D[n-m-i..n-1-i]));
        X(compare_result);
        // if compare_result = 1, D < Q, D = D[n-1-i...n-m-i] + D[n-m-1...0]
        // if D[n-1-i] = 0, the highest bit of this mindend is 0, no need to subtract
        if (i != n-m) {
            CNOT(D[n-1-i], S[n-m-i-1]); 
            CCNOT(compare_result, D[n-1-i], acc);
            Controlled Subtract_NotEqualBit([acc], (Q[0..m-1], D[n-m-i-1..n-1-i]));
            CCNOT(compare_result, S[n-m-i-1], acc); // the paper use reset
        }
        Reset(compare_result);
    }
}
export Divide;
