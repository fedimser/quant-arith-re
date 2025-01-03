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
    Fact(a_val >= 0, "a>=0");
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

// Computes (a_val*b_val)%mod using FMAC_MOD2.
operation TestFMAC_MOD2(n : Int, a_val : Int, b_val : Int, mod : Int) : Int {
    Fact(b_val >= 0 and b_val < (1 <<< n), "b_val out of bounds.");
    Fact(((a_val * b_val) / mod) < (1 <<< n), "Must be (a*b)<N < 2^n.");

    use a = Qubit[n];
    use ans = Qubit[n];
    use c = Qubit();
    ApplyPauliFromInt(PauliX, true, a_val, a);

    within {
        X(c);
    } apply {
        QuantumArithmetic.PG2012.FMAC_MOD2(c, a, ans, IntAsBigInt(b_val), IntAsBigInt(mod));
    }
    Fact(MeasureInteger(a) == a_val, "Register a was changed.");
    return MeasureInteger(ans);
}

// Computes (a_val*b_val)%mod using FMUL_MOD2.
// Must be gcd(b_val,mod)=1.
operation TestFMUL_MOD2(n : Int, a_val : Int, b_val : Int, mod : Int) : Int {
    Fact(b_val >= 0 and b_val < (1 <<< n), "b_val out of bounds.");
    Fact(((a_val * b_val) / mod) < (1 <<< n), "Must be (a*b)<N < 2^n.");

    use a = Qubit[n];
    use c = Qubit();
    ApplyPauliFromInt(PauliX, true, a_val, a);

    within {
        X(c);
    } apply {
        QuantumArithmetic.PG2012.FMUL_MOD2(c, a, IntAsBigInt(b_val), IntAsBigInt(mod));
    }
    return MeasureInteger(a);
}
