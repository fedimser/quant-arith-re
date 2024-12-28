import Std.Diagnostics.Fact;
import QuantumArithmetic.TMVH2019.Config;
import TestUtils.*;

// Helper to test Divide_TMVH_Restoring.
// n is number of bits per register.
// Returns pair (a_val/b_val, a_val%b_val).
operation Test_Divide_Restoring(n : Int, a_val : BigInt, b_val : BigInt, cfg : Config) : (BigInt, BigInt) {
    Fact(b_val < (1L <<< (n-1)), "Must be b<2^(n-1).");
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n];
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    QuantumArithmetic.TMVH2019.Divide_Restoring(a, b, c, cfg);
    let q_val = MeasureBigInt(c);
    let new_b_val = MeasureBigInt(b);
    let r_val = MeasureBigInt(a);
    Fact(new_b_val == b_val, "b was changed.");
    return (q_val, r_val);
}

// Helper to test Divide_TMVH_NonRestoring.
// n is number of bits per register.
// Returns pair (a_val/b_val, a_val%b_val).
operation Test_Divide_NonRestoring(n : Int, a_val : BigInt, b_val : BigInt, cfg : Config) : (BigInt, BigInt) {
    Fact(b_val < (1L <<< (n-1)), "Must be b<2^(n-1).");
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n-1];
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    QuantumArithmetic.TMVH2019.Divide_NonRestoring(a, b, c, cfg);
    let q_val = MeasureBigInt([a[n-1]] + c);
    let new_b_val = MeasureBigInt(b);
    let r_val = MeasureBigInt(a[0..n-2]);
    Fact(new_b_val == b_val, "b was changed.");
    return (q_val, r_val);
}

operation Run_Restoring(n : Int, adder : (Qubit[], Qubit[]) => Unit is Adj + Ctl) : Unit {
    let cfg = new Config { Adder = adder };
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n];
    QuantumArithmetic.TMVH2019.Divide_Restoring(a, b, c, cfg);
}

operation Run_NonRestoring(n : Int, adder : (Qubit[], Qubit[]) => Unit is Adj + Ctl) : Unit {
    let cfg = new Config { Adder = adder };
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n-1];
    QuantumArithmetic.TMVH2019.Divide_NonRestoring(a, b, c, cfg);
}
