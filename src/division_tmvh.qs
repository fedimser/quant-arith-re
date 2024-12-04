/// Implementation of 2 division algorithms presented in the paper:
///   Quantum Circuit Designs of Integer Division Optimizing T-count and T-depth,
///   Thapliyal, Munoz-Coreas, Varun, Humble, 2019, https://arxiv.org/pdf/1809.09732.

namespace QuantumArithmetic {
    import Std.Diagnostics.Fact;

    // Computes ys+=xs if ctrl=1, does nothing if ctrl=0.
    operation CtrlAdd(ctrl : Qubit, xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
        Controlled Std.Arithmetic.RippleCarryTTKIncByLE([ctrl], (xs, ys));
    }

    // Computes ys-=xs if ctrl=1, and ys+=xs if ctrl=0.
    operation AddSub(ctrl : Qubit, xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
        let ysLen = Length(ys);
        for i in 0..ysLen-1 {
            CNOT(ctrl, ys[i]);
        }
        Std.Arithmetic.RippleCarryTTKIncByLE(xs, ys);
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
    /// All numbers are little-endian.
    operation Divide_TMVH_Restoring(a : Qubit[], b : Qubit[], c : Qubit[]) : Unit is Adj + Ctl {
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
    /// All numbers are little-endian.
    operation Divide_TMVH_NonRestoring(a : Qubit[], b : Qubit[], c : Qubit[]) : Unit is Adj + Ctl {
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
}

namespace QuantumArithmetic.Test {
    import Std.Diagnostics.Fact;
    
    // Helper to test Divide_TMVH_Restoring.
    // n is number of bits per register.
    // Returns pair (a_val/b_val, a_val%b_val).
    operation Test_Divide_TMVH_Restoring(n : Int, a_val : Int, b_val : Int) : (Int, Int) {
        Fact(b_val < (1 <<< (n-1)), "Must be b<2^(n-1).");
        use a = Qubit[n];
        use b = Qubit[n];
        use c = Qubit[n];
        ApplyPauliFromInt(PauliX, true, a_val, a);
        ApplyPauliFromInt(PauliX, true, b_val, b);
        QuantumArithmetic.Divide_TMVH_Restoring(a, b, c);
        let q_val = MeasureInteger(c);
        let new_b_val = MeasureInteger(b);
        let r_val = MeasureInteger(a);
        Fact(new_b_val == b_val, "b was changed.");
        return (q_val, r_val);
    }

    // Helper to test Divide_TMVH_NonRestoring.
    // n is number of bits per register.
    // Returns pair (a_val/b_val, a_val%b_val).
    operation Test_Divide_TMVH_NonRestoring(n : Int, a_val : Int, b_val : Int) : (Int, Int) {
        Fact(b_val < (1 <<< (n-1)), "Must be b<2^(n-1).");
        use a = Qubit[n];
        use b = Qubit[n];
        use c = Qubit[n-1];
        ApplyPauliFromInt(PauliX, true, a_val, a);
        ApplyPauliFromInt(PauliX, true, b_val, b);
        QuantumArithmetic.Divide_TMVH_NonRestoring(a, b, c);
        let q_val = MeasureInteger([a[n-1]] + c);
        let new_b_val = MeasureInteger(b);
        let r_val = MeasureInteger(a[0..n-2]);
        Fact(new_b_val == b_val, "b was changed.");
        return (q_val, r_val);
    }
}