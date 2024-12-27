import Std.Convert.BigIntAsBoolArray;
import Std.Diagnostics.Fact;
import Std.Math.ExpModI;


// Writes little-endian integer to quantum register (prepared in 0 state).
operation ApplyBigInt(val : BigInt, reg : Qubit[]) : Unit is Adj + Ctl {
    let bits = BigIntAsBoolArray(val, Length(reg));
    ApplyPauliFromBitString(PauliX, true, bits, reg);
}

// Measures content of register as little-endian BigInt.
// Resets register to zero state.
operation MeasureBigInt(reg : Qubit[]) : BigInt {
    let n = Length(reg);
    mutable base : BigInt = 1L;
    mutable ans : BigInt = 0L;
    for i in 0..n-1 {
        let measurement = MResetZ(reg[i]);
        if (measurement == One) {
            set ans += base;
        }
        set base *= 2L;
    }
    return ans;
}

// Applies binary operation on quantum integers.
// 1. Creates qubit register x of size n, populates it with integer x_val.
// 2. Creates qubit register y of size n, populates it with integer y_val.
// 3. Creates qubit register z of size n, initialized with zeros.
// 3. Calls op(x, y, z).
// 4. Measures value in z and returns it. Also checks that x and y were unchanged.
// All numbers are little-endian.
operation BinaryOp(n : Int, x_val : BigInt, y_val : BigInt, op : (Qubit[], Qubit[], Qubit[]) => Unit) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let new_y = MeasureBigInt(y);
    Fact(new_y == y_val, "y was changed.");
    let new_z = MeasureBigInt(z);
    return new_z;
}

// Applies binary operation on quantum integers, in-place.
// 1. Creates qubit register x of size n, populates it with integer x_val.
// 2. Creates qubit register y of size n, populates it with integer y_val.
// 3. Calls op(x, y).
// 4. Measures value in y and returns it. Also checks that x was unchanged.
// All numbers are little-endian.
operation BinaryOpInPlace(n : Int, x_val : BigInt, y_val : BigInt, op : (Qubit[], Qubit[]) => Unit) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let ans = MeasureBigInt(y);
    return ans;
}

operation BinaryOpInPlaceExtraOut(n : Int, x_val : BigInt, y_val : BigInt, op : (Qubit[], Qubit[], Qubit) => Unit) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit();
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let results = y + [z];
    let ans = MeasureBigInt(results);
    return ans;
}

operation BinaryOpExtraOut(n : Int, x_val : BigInt, y_val : BigInt, op : (Qubit[], Qubit[], Qubit[], Qubit) => Unit) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    use z_extra = Qubit();
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    op(x, y, z, z_extra);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let new_z = MeasureBigInt(z);
    Fact(new_z == y_val, "z was not changed to y.");
    let results = y + [z_extra];
    let ans = MeasureBigInt(results);
    return ans;
}

// Computes op(x).
operation UnaryOpInPlace(n : Int, x_val : BigInt, op : (Qubit[]) => Unit) : BigInt {
    use x = Qubit[n];
    ApplyBigInt(x_val, x);
    op(x);
    return MeasureBigInt(x);
}

// Calculates a_val*b_val using out-of-place multiplier `op`.
// Inputs sizes are `a_size` and `b_size`. Output size is `a_size+b_size`.
operation TestMultiply(a_size : Int, b_size : Int, a_val : BigInt, b_val : BigInt, op : (Qubit[], Qubit[], Qubit[]) => Unit) : BigInt {
    use a = Qubit[a_size];
    use b = Qubit[b_size];
    use ans = Qubit[a_size + b_size];
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    op(a, b, ans);
    Fact(MeasureBigInt(a) == a_val, "a was changed.");
    Fact(MeasureBigInt(b) == b_val, "b was changed.");
    return MeasureBigInt(ans);
}

// n is number of bits per register.
// Returns pair (a_val/b_val, a_val%b_val).
operation Test_Divide_Restoring(n : Int, a_val : Int, b_val : Int, op : (Qubit[], Qubit[], Qubit[]) => Unit) : (Int, Int) {
    Fact(b_val < (1 <<< (n-1)), "Must be b<2^(n-1).");
    use a = Qubit[n];
    use b = Qubit[n];
    use q = Qubit[n];
    ApplyPauliFromInt(PauliX, true, a_val, a);
    ApplyPauliFromInt(PauliX, true, b_val, b);
    op(a, b, q);
    let q_val = MeasureInteger(q);
    let new_b_val = MeasureInteger(b);
    let new_a_val = MeasureInteger(a);
    Fact(new_b_val == b_val, "b was changed.");
    Message($"a={new_a_val} b={new_b_val} q={q_val}");
    return (q_val, new_a_val);
}

operation BinaryOpInPlaceRadix(n : Int, x_val : Int, y_val : Int, radix : Int, op : (Qubit[], Qubit[], Int) => Unit) : Int {
    use x = Qubit[n];
    use y = Qubit[n];
    ApplyPauliFromInt(PauliX, true, x_val, x);
    ApplyPauliFromInt(PauliX, true, y_val, y);
    op(x, y, radix);
    let new_x = MeasureInteger(x);
    Fact(new_x == x_val, "x was changed.");
    let ans = MeasureInteger(y);
    return ans;
}