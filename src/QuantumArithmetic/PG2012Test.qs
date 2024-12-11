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
        X(c);
        ApplyQFT(b);
    } apply {
        QuantumArithmetic.PG2012.FMAC_Unoptimized(c, IntAsBigInt(a), x, b);
    }
    Fact(MeasureInteger(x) == x_val, "x was changed.");
    let ans = MeasureInteger(b);

    ApplyPauliFromInt(PauliX, true, b_val, b);
    ApplyPauliFromInt(PauliX, true, x_val, x);
    within {
        X(c);
        ApplyQFT(b);
    } apply {
        QuantumArithmetic.PG2012.FMAC(c, IntAsBigInt(a), x, b);
    }
    Fact(MeasureInteger(x) == x_val, "x was changed.");
    Fact(MeasureInteger(b) == ans, "Answers don't match.");
    return ans;
}

