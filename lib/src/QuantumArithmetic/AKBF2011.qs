/// Implementation of a restoring division algorithms presented in the paper:
///   Quantum Division Circuit Based on Restoring Division Algorithm, https://ieeexplore.ieee.org/document/5945378/

import Std.Diagnostics.Fact;
import Std.Arithmetic.ApplyIfGreaterOrEqualLE;
import Std.Arithmetic.ApplyIfGreaterLE;
import QuantumArithmetic.TMVH2019.Subtract;

/// Computes a,b,c:=(a%b,b,a//b).
///
/// Constraints:
///  * a,b,c must have the same number of qubits n.
///  * 0 <= a < 2^n.
///  * 0 < b < 2^(n-1).
///  * c must be initialized to zeros.
operation Divide_Restoring(a : Qubit[], b : Qubit[], q : Qubit[]) : Unit is Adj + Ctl {
    let cfg = new QuantumArithmetic.TMVH2019.Config { Adder = Std.Arithmetic.RippleCarryTTKIncByLE };
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes must match.");
    // Fact(Length(r) == n, "Registers sizes must match.");
    Fact(Length(q) == n, "Registers sizes must match.");
    use acc_P = Qubit[n];
    use acc_D = Qubit[n];
    let D = acc_D + b;
    use zero = Qubit[1];
    for i in 0..n-1 {
        // Step 1: Multiply P by 2 (right shift)
        let P = acc_P[n-1-i..n-1] + a[0..n-1] + acc_P[0..n-2-i];
        // Step 2: Compare PShift and D, if positive, set the next quotient bit to 1, and subtract D from PShift
        ApplyIfGreaterOrEqualLE(X, P, D, q[n-1-i]);
        ApplyIfGreaterLE(Subtract, [q[n-1-i]], zero, (D, P, cfg));
    }
}
export Divide_Restoring;
