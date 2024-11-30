namespace QuantumArithmetic.Test {
    import Std.Diagnostics.Fact;
    import Std.Arithmetic.IncByLE;

    // TODO: do we have this in standard library?
    operation MeasureRegisterToLE(reg : Qubit[]) : Int {
        let n = Length(reg);
        mutable base : Int = 1;
        mutable ans : Int = 0;
        for i in 0..n-1 {
            let measurement = M(reg[i]);
            if (measurement == One) {
                set ans += base;
            }
            set base *= 2;
        }
        return ans;
    }

    // TODO: do we have this in standard library?
    operation EncodeIntegerToRegister(val: Int, reg : Qubit[]) : Unit {
        let n = Length(reg);
        mutable v = val;
        for i in 0..n-1 {
            if (v % 2==1) {
                X(reg[i]);
            }
            set v /=2;
        }
        Fact(v==0, "Register is too small.");
    }

    // 1. Creates qubit register x of size xn, populates it with integer x_val.
    // 2. Creates qubit register y of size yn, populates it with integer y_val.
    // 3. Calls op(x, y).
    // 4. Measures value in y and returns it.
    // All numbers are little-endian.
    operation PerformArithmeticOperationInPlace(xn: Int, yn: Int, x_val: Int, y_val: Int, op: (Qubit[], Qubit[]) => Unit) : Int {
        use x = Qubit[xn];
        use y = Qubit[yn];
        EncodeIntegerToRegister(x_val, x);
        EncodeIntegerToRegister(y_val, y);
        op(x, y);
        let ans = MeasureRegisterToLE(y);
        ResetAll(x);
        ResetAll(y);
        return ans;
    }
}