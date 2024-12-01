namespace QuantumArithmetic.Test {
    import Std.Diagnostics.Fact;
    import Std.Arithmetic.IncByLE;

    // Reads out little-endian value of qubit using measurements.
    // Leaves reg in all-zeros state.
    operation MeasureRegisterToLE(reg : Qubit[]) : Int {
        let n = Length(reg);
        mutable base : Int = 1;
        mutable ans : Int = 0;
        for i in 0..n-1 {
            let measurement = M(reg[i]);
            if (measurement == One) {
                X(reg[i]);
                set ans += base;
            }
            set base *= 2;
        }
        return ans;
    }

    // Writes non-negative little-endian integer to quantum register.
    // reg must be prepared in all-zeros state.
    operation EncodeIntegerToRegister(val : Int, reg : Qubit[]) : Unit {
        Fact(val >= 0, "Value must be non-negative.");
        let n = Length(reg);
        mutable v = val;
        for i in 0..n-1 {
            if (v % 2 == 1) {
                X(reg[i]);
            }
            set v /= 2;
        }
        Fact(v == 0, "Register is too small.");
    }

    // 1. Creates qubit register x of size xn, populates it with integer x_val.
    // 2. Creates qubit register y of size yn, populates it with integer y_val.
    // 3. Calls op(x, y).
    // 4. Measures value in y and returns it. Also checks that x was unchanged.
    // All numbers are little-endian.
    operation PerformArithmeticOperationInPlace(xn : Int, yn : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[]) => Unit) : Int {
        use x = Qubit[xn];
        use y = Qubit[yn];
        EncodeIntegerToRegister(x_val, x);
        EncodeIntegerToRegister(y_val, y);
        op(x, y);
        let new_x = MeasureRegisterToLE(x);
        Fact(new_x == x_val, "x was changed.");
        let ans = MeasureRegisterToLE(y);
        return ans;
    }
}