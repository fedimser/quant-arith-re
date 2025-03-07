import Std.Diagnostics.Fact;
import TestUtils.*;

operation BinaryOpRadix(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int) => Unit) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z, radix);
    let new_x = MeasureBigInt(x);
    let new_y = MeasureBigInt(y);
    let ans = MeasureBigInt(z);
    return ans;
}

operation BinaryOpRadixWithOp(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int, (Qubit[], Qubit[], Qubit[]) => Unit is Adj) => Unit, adder_op : (Qubit[], Qubit[], Qubit[]) => Unit is Adj) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z, radix, adder_op);
    let new_x = MeasureBigInt(x);
    let new_y = MeasureBigInt(y);
    let ans = MeasureBigInt(z);
    return ans;
}

operation BinaryOpRadixWithCarry(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int, (Qubit[], Qubit[], Qubit[], Qubit) => Unit is Adj) => Unit, adder_op : (Qubit[], Qubit[], Qubit[], Qubit) => Unit is Adj) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z, radix, adder_op);
    let new_x = MeasureBigInt(x);
    let new_y = MeasureBigInt(y);
    let ans = MeasureBigInt(z);
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