import Std.Math.ExpModI;
import Std.Diagnostics.Fact;

// Applies binary operation on quantum integers.
// 1. Creates qubit register x of size n, populates it with integer x_val.
// 2. Creates qubit register y of size n, populates it with integer y_val.
// 3. Creates qubit register z of size n, initialized with zeros.
// 3. Calls op(x, y, z).
// 4. Measures value in z and returns it. Also checks that x and y were unchanged.
// All numbers are little-endian.
operation BinaryOp(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[], Qubit[]) => Unit) : Int {
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

// Applies binary operation on quantum integers, in-place.
// 1. Creates qubit register x of size n, populates it with integer x_val.
// 2. Creates qubit register y of size n, populates it with integer y_val.
// 3. Calls op(x, y).
// 4. Measures value in y and returns it. Also checks that x was unchanged.
// All numbers are little-endian.
operation BinaryOpInPlace(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[]) => Unit) : Int {
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

operation BinaryOpInPlaceExtraOut(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[], Qubit) => Unit) : Int {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit();
    ApplyPauliFromInt(PauliX, true, x_val, x);
    ApplyPauliFromInt(PauliX, true, y_val, y);
    op(x, y, z);
    let new_x = MeasureInteger(x);
    Fact(new_x == x_val, "x was changed.");
    let results = y + [z];
    let ans = MeasureInteger(results);
    return ans;
}

operation BinaryOpExtraOut(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[], Qubit[], Qubit) => Unit) : Int {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    use z_extra = Qubit();
    ApplyPauliFromInt(PauliX, true, x_val, x);
    ApplyPauliFromInt(PauliX, true, y_val, y);
    op(x, y, z, z_extra);
    let new_x = MeasureInteger(x);
    Fact(new_x == x_val, "x was changed.");
    let new_z = MeasureInteger(z);
    Fact(new_z == y_val, "z was not changed to y.");
    // let results = y + [z_extra];
    let results = y;
    let z = MeasureInteger([z_extra]);
    let ans = MeasureInteger(results);
    return ans;
}

// Computes op(x).
operation UnaryOpInPlace(n : Int, x_val : Int, op : (Qubit[]) => Unit) : Int {
    use x = Qubit[n];
    ApplyPauliFromInt(PauliX, true, x_val, x);
    op(x);
    return MeasureInteger(x);
}