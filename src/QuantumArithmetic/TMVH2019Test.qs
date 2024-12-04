import Std.Diagnostics.Fact;

// Helper to test Divide_TMVH_Restoring.
// n is number of bits per register.
// Returns pair (a_val/b_val, a_val%b_val).
operation Test_Divide_Restoring(n : Int, a_val : Int, b_val : Int) : (Int, Int) {
    Fact(b_val < (1 <<< (n-1)), "Must be b<2^(n-1).");
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n];
    ApplyPauliFromInt(PauliX, true, a_val, a);
    ApplyPauliFromInt(PauliX, true, b_val, b);
    QuantumArithmetic.TMVH2019.Divide_Restoring(a, b, c);
    let q_val = MeasureInteger(c);
    let new_b_val = MeasureInteger(b);
    let r_val = MeasureInteger(a);
    Fact(new_b_val == b_val, "b was changed.");
    return (q_val, r_val);
}

// Helper to test Divide_TMVH_NonRestoring.
// n is number of bits per register.
// Returns pair (a_val/b_val, a_val%b_val).
operation Test_Divide_NonRestoring(n : Int, a_val : Int, b_val : Int) : (Int, Int) {
    Fact(b_val < (1 <<< (n-1)), "Must be b<2^(n-1).");
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n-1];
    ApplyPauliFromInt(PauliX, true, a_val, a);
    ApplyPauliFromInt(PauliX, true, b_val, b);
    QuantumArithmetic.TMVH2019.Divide_NonRestoring(a, b, c);
    let q_val = MeasureInteger([a[n-1]] + c);
    let new_b_val = MeasureInteger(b);
    let r_val = MeasureInteger(a[0..n-2]);
    Fact(new_b_val == b_val, "b was changed.");
    return (q_val, r_val);
}
