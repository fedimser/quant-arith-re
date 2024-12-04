namespace QuantumArithmetic.Test {
    import Std.Diagnostics.Fact;

    // 1. Creates qubit register x of size n, populates it with integer x_val.
    // 2. Creates qubit register y of size n, populates it with integer y_val.
    // 3. Creates qubit register z of size n, initialized with zeros.
    // 3. Calls op(x, y, z).
    // 4. Measures value in z and returns it. Also checks that x and y were unchanged.
    // All numbers are little-endian.
    operation PerformArithmeticOperation(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[], Qubit[]) => Unit) : Int {
        use x = Qubit[n];
        use y = Qubit[n];
        use z = Qubit[n];
        ApplyPauliFromInt(PauliX, true, x_val, x);
        ApplyPauliFromInt(PauliX, true, y_val, y);
        op(x, y, z);
        let new_x = MeasureInteger(x);
        Fact(new_x == x_val, "x was changed.");
        let new_y = MeasureInteger(y);
        Fact(new_y == y_val, "y was changed.");
        let new_z = MeasureInteger(z);
        return new_z;
    }

    // 1. Creates qubit register x of size n, populates it with integer x_val.
    // 2. Creates qubit register y of size n, populates it with integer y_val.
    // 3. Calls op(x, y).
    // 4. Measures value in y and returns it. Also checks that x was unchanged.
    // All numbers are little-endian.
    operation PerformArithmeticOperationInPlace(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[]) => Unit) : Int {
        use x = Qubit[n];
        use y = Qubit[n];
        ApplyPauliFromInt(PauliX, true, x_val, x);
        ApplyPauliFromInt(PauliX, true, y_val, y);
        op(x, y);
        let new_x = MeasureInteger(x);
        Fact(new_x == x_val, "x was changed.");
        let ans = MeasureInteger(y);
        return ans;
    }
}