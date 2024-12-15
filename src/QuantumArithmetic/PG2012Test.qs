/// Implementation of operations presented in paper:
///   Fast quantum modular exponentiation architecture for Shor's factoring algorithm
///   Archimedes Pavlidis and Dimitris Gizopoulos, 2012.
///   https://arxiv.org/pdf/1207.0511

import Std.Convert.IntAsBigInt;
import Std.Diagnostics.Fact;

// Computes a+b_val using FADD circuit.
operation TestFADD(n : Int, a : Int, b_val : Int) : Int {
    Fact(a < (1 <<< n), "a<2^n");
    Fact(b_val < (1 <<< n), "b<2^n");

    use b = Qubit[n];
    ApplyPauliFromInt(PauliX, true, b_val, b);
    within {
        ApplyQFT(b);
    } apply {
        QuantumArithmetic.PG2012.FADD(IntAsBigInt(a), b);
    }
    return MeasureInteger(b);
}

// Computes a_val+b_val using FADD2 circuit.
operation TestFADD2(n : Int, a_val : Int, b_val : Int) : Int {
    Fact(a_val < (1 <<< n), "a<2^n");
    Fact(b_val < (1 <<< n), "b<2^n");

    use a = Qubit[n];
    use b = Qubit[n];
    ApplyPauliFromInt(PauliX, true, a_val, a);
    ApplyPauliFromInt(PauliX, true, b_val, b);
    within {
        ApplyQFT(b);
    } apply {
        QuantumArithmetic.PG2012.FADD2(a, b);
    }
    Fact(MeasureInteger(a) == a_val, "a was changed.");
    return MeasureInteger(b);
}

// Computes b_val+a*x_val using FMAC circuit (optimized and unoptimized).
operation TestFMAC(n : Int, a : Int, b_val : Int, x_val : Int) : Int {
    Fact(a < (1 <<< n), "a<2^n");
    Fact(b_val < (1 <<< (2 * n)), "b<4^n");
    Fact(x_val < (1 <<< n), "x<2^n");

    use x = Qubit[n];
    use b = Qubit[2 * n];
    use c = Qubit();

    ApplyPauliFromInt(PauliX, true, b_val, b);
    ApplyPauliFromInt(PauliX, true, x_val, x);
    within {
        ApplyQFT(b);
    } apply {
        QuantumArithmetic.PG2012.FMAC(IntAsBigInt(a), x, b);
    }
    Fact(MeasureInteger(x) == x_val, "x was changed.");
    let ans = MeasureInteger(b);

    ApplyPauliFromInt(PauliX, true, b_val, b);
    ApplyPauliFromInt(PauliX, true, x_val, x);
    within {
        X(c);
        ApplyQFT(b);
    } apply {
        QuantumArithmetic.PG2012.ControlledFMAC(c, IntAsBigInt(a), x, b);
    }
    Fact(MeasureInteger(x) == x_val, "x was changed.");
    Fact(MeasureInteger(b) == ans, "Answers don't match.");
    return ans;
}

// a is 2n-bit number, b is n-bit number.
// Returns pair (a_val/b_val, a_val%b_val).
operation TestGMFDIV(n : Int, a_val : Int, b_val : Int) : (Int, Int) {
    Fact(a_val >= 0, "a>=0"); // Needed?
    Fact(a_val < (1 <<< (2 * n)), "a<2^(2n)");
    let q_true = a_val / b_val;
    Fact(q_true < (1 <<< n), "q<2^n");

    use a = Qubit[2 * n];
    use q = Qubit[n];
    ApplyPauliFromInt(PauliX, true, a_val, a);
    QuantumArithmetic.PG2012.GMFDIV2(a, IntAsBigInt(b_val), q);
    let q_val = MeasureInteger(q);
    let r_val = MeasureInteger(a);
    return (q_val, r_val);
}