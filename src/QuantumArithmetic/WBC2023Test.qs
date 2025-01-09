import Std.Diagnostics.Fact;
import TestUtils.*;

operation BinaryOpRadix(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int) => Unit) : BigInt {
    // Message($"x_val={x_val} y_val={y_val} n={n}");
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z, radix);
    let new_x = MeasureBigInt(x);
    let new_y = MeasureBigInt(y);
    let ans = MeasureBigInt(z);
    // Message($"x_val={x_val} y_val={y_val} n={n} x={new_x} y={new_y} z={ans}");
    return ans;
}

operation BinaryOpInPlaceRadix(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Int) => Unit) : BigInt {
    Message($"x_val={x_val} y_val={y_val}");
    use x = Qubit[n];
    use y = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, radix);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let ans = MeasureBigInt(y);
    Message($"x={new_x} y={ans}");
    return ans;
}

operation BinaryOpInPlaceRadixNew(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int) => Unit) : BigInt {
    Message($"x_val={x_val} y_val={y_val}");
    use x = Qubit[n];
    use y = Qubit[n];
    use g = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, g, radix);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let ans = MeasureBigInt(y);
    let new_g = MeasureBigInt(g);
    Message($"x={new_x} y={ans} g={new_g}");
    return ans;
}