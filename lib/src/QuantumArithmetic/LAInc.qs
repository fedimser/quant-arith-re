/// Low-ancilla incrementer circuit.


function Log2(x : Int) : Double {
    return Std.Math.Log(Std.Convert.IntAsDouble(x)) / Std.Math.LogOf2();
}

/// Computes ans := CTO(x), where CTO(x) is number of trailing (least
/// significant) "1" bits in register x before first zero bit. CTO(0)=0.
/// ans must be prepared in zero state.
operation CountTrailingOnes(x : Qubit[], ans : Qubit[]) : Unit is Ctl + Adj {
    let x_len = Length(x);
    if (x_len == 1) {
        CNOT(x[0], ans[0]);
    } elif (x_len == 2) {
        X(x[1]);
        CCNOT(x[0], x[1], ans[0]);
        X(x[1]);
        CCNOT(x[0], x[1], ans[1]);
    } else {
        let n : Int = Std.Math.Ceiling(Log2(x_len));
        let x_low = x[0..(1 <<< (n - 1))-1];
        let x_high = x[(1 <<< (n - 1))..x_len-1];
        if (x_len == 1 <<< n) {
            Std.Diagnostics.Fact(Length(ans) >= n + 1, "ans too small");
            CountTrailingOnes(x_low, ans[0..n-1]);
            Controlled CountTrailingOnes([ans[n-1]], (x_high, ans[0..n-2] + [ans[n]]));
            CNOT(ans[n], ans[n-1]);
        } else {
            Std.Diagnostics.Fact(Length(ans) >= n, "ans too small");
            CountTrailingOnes(x_low, ans[0..n-1]);
            Controlled CountTrailingOnes([ans[n-1]], (x_high, ans[0..n-2]));
        }
    }
} 