import Std.Arrays.Reversed;
import Std.Convert;
import Std.Diagnostics.Fact;
import Std.Math.ExpModI;
import Std.StatePreparation.PreparePureStateD;

// Writes little-endian integer to quantum register (prepared in 0 state).
operation ApplyBigInt(val : BigInt, reg : Qubit[]) : Unit is Adj + Ctl {
    let bits = Convert.BigIntAsBoolArray(val, Length(reg));
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

// Tests arbitrary operation acting on 2 registers.
// Applies `op` on two registers of sizes nx, ny, populated with x,y.
// Returns new values of the registers.
operation BinaryOpArb(
    nx : Int,
    ny : Int,
    x : BigInt,
    y : BigInt,
    op : (Qubit[], Qubit[]) => Unit
) : (BigInt, BigInt) {
    use X = Qubit[nx];
    use Y = Qubit[ny];
    ApplyBigInt(x, X);
    ApplyBigInt(y, Y);
    op(X, Y);
    return (MeasureBigInt(X), MeasureBigInt(Y));
}


// Tests arbitrary operation acting on 3 registers.
// Applies `op` on three registers of sizes nx, ny, nz, populated with x,y,z.
// Returns new values of the registers.
operation TernaryOp(
    nx : Int,
    ny : Int,
    nz : Int,
    x : BigInt,
    y : BigInt,
    z : BigInt,
    op : (Qubit[], Qubit[], Qubit[]) => Unit
) : (BigInt, BigInt, BigInt) {
    use X = Qubit[nx];
    use Y = Qubit[ny];
    use Z = Qubit[nz];
    ApplyBigInt(x, X);
    ApplyBigInt(y, Y);
    ApplyBigInt(z, Z);
    op(X, Y, Z);
    return (MeasureBigInt(X), MeasureBigInt(Y), MeasureBigInt(Z));
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

/// Computes op(x).
/// Also checks that Controlled functor is implemented correctly (at least for
/// single control).
operation UnaryOpInPlaceCtl(n : Int, x_val : BigInt, op : (Qubit[]) => Unit is Ctl) : BigInt {
    use ctrl = Qubit();
    use x = Qubit[n];

    ApplyBigInt(x_val, x);
    Controlled op([ctrl], (x));
    Fact(MeasureBigInt(x) == x_val, "Must not change when ctrl=0");

    ApplyBigInt(x_val, x);
    X(ctrl);
    Controlled op([ctrl], (x));
    X(ctrl);
    let ans1 = MeasureBigInt(x);

    ApplyBigInt(x_val, x);
    op(x);
    let ans2 = MeasureBigInt(x);
    Fact(ans1 == ans2, $"Different results from controlled({ans1})/uncontrolled({ans2}).");
    return ans2;
}

// Calculates a_val*b_val using out-of-place multiplier `op`.
// Inputs sizes are `nx` and `ny`. Output size is `nx+ny`.
operation TestMultiply(nx : Int, ny : Int, x : BigInt, y : BigInt, op : (Qubit[], Qubit[], Qubit[]) => Unit) : BigInt {
    let (new_x, new_y, ans) = TernaryOp(nx, ny, nx + ny, x, y, 0L, op);
    Fact(new_x == x, "x was changed.");
    Fact(new_y == y, "y was changed.");
    return ans;
}

/// Calculates (a^x)%N using given operation.
operation TestModExp(n : Int, a : BigInt, x : BigInt, N : BigInt, op : (Qubit[], Qubit[], BigInt, BigInt) => Unit) : BigInt {
    use ans = Qubit[n];
    use x_qubits = Qubit[n];
    ApplyBigInt(x, x_qubits);
    op(x_qubits, ans, a, N);
    Fact(MeasureBigInt(x_qubits) == x, "Register x was changed.");
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

// n is number of bits per register.
// Returns pair (a_val/b_val, a_val%b_val).
operation Test_Divide_Unequal(n : Int, a_val : Int, m : Int, b_val : Int, op : (Qubit[], Qubit[], Qubit[]) => Unit) : (Int, Int) {
    // Fact(b_val < (1 <<< (n-1)), "Must be b<2^(n-1).");
    Fact(m < n, "Must be m<n.");
    use a = Qubit[n];
    use b = Qubit[m];
    use q = Qubit[n-m + 1];
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

operation BinaryOpInPlaceRadix(n : Int, x_val : Int, y_val : Int, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int) => Unit) : Int {
    Message($"x_val={x_val} y_val={y_val} radix={radix}");
    use x = Qubit[n];
    use y = Qubit[n];
    use g = Qubit[n];
    ApplyPauliFromInt(PauliX, true, x_val, x);
    ApplyPauliFromInt(PauliX, true, y_val, y);
    op(x, y, g, radix);
    let new_x = MeasureInteger(x);
    Fact(new_x == x_val, "x was changed.");
    let ans = MeasureInteger(y);
    let new_g = MeasureInteger(g);
    Message($"x={new_x} y={ans} g={new_g}");
    return ans;
}

operation UnaryPredicateCtl(n : Int, x_val : BigInt, op : (Qubit[], Qubit) => Unit is Ctl) : Bool {
    use ctrl = Qubit();
    use x = Qubit[n];
    use ans = Qubit();

    ApplyBigInt(x_val, x);
    Controlled op([ctrl], (x, ans));
    Fact(MResetZ(ans) == Zero, "Must return false when ctrl=false.");

    X(ctrl);
    Controlled op([ctrl], (x, ans));
    X(ctrl);
    let ans1 : Bool = (MResetZ(ans) == One);

    op(x, ans);
    let ans2 : Bool = (MResetZ(ans) == One);
    Fact(MeasureBigInt(x) == x_val, "x was changed.");
    Fact(ans1 == ans2, $"Different results from controlled({ans1})/uncontrolled({ans2}).");
    return ans2;
}

operation TestCompare(n : Int, a_val : BigInt, b_val : BigInt, op : (Qubit[], Qubit[], Qubit) => Unit) : Bool {
    use a = Qubit[n];
    use b = Qubit[n];
    use ans = Qubit();
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    op(a, b, ans);
    Fact(MeasureBigInt(a) == a_val, "a was changed.");
    Fact(MeasureBigInt(b) == b_val, "b was changed.");
    // a < b if ans=1, return true
    return MResetZ(ans) == One;
}

operation Test_Subtract_NotEqualBit(n : Int, a_val : BigInt, m : Int, b_val : BigInt, c_val : Int, op : (Qubit[], Qubit[], Qubit, Qubit) => Unit) : BigInt {
    use a = Qubit[n];
    use b = Qubit[m];
    use s2 = Qubit();
    use ctr = Qubit();
    if (c_val == 1) {
        X(ctr);
    }
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    op(a, b, s2, ctr);
    Fact(MeasureBigInt(a) == a_val, "a was changed.");
    Fact(MeasureInteger([ctr]) == c_val, "Control qubit was changed.");
    return MeasureBigInt(b + [s2]);
}

operation Test_Subtract_Minuend(n : Int, a_val : BigInt, b_val : BigInt, op : (Qubit[], Qubit[]) => Unit) : BigInt {
    use a = Qubit[n];
    use b = Qubit[n];
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    op(a, b);
    Fact(MeasureBigInt(a) == a_val, "a was changed.");
    return MeasureBigInt(b);
}

operation Test_Subtract_Minuend_Unequal(n : Int, a_val : BigInt, m : Int, b_val : BigInt, op : (Qubit[], Qubit[]) => Unit) : BigInt {
    use a = Qubit[n];
    use b = Qubit[m];
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    op(a, b);
    Fact(MeasureBigInt(a) == a_val, "a was changed.");
    return MeasureBigInt(b);
}

operation Test_Subtract(n : Int, a_val : BigInt, b_val : BigInt, c_val : Int, op : (Qubit[], Qubit[], Qubit) => Unit) : BigInt {
    use a = Qubit[n];
    use b = Qubit[n];
    use ctr = Qubit();
    if (c_val == 1) {
        X(ctr);
    }
    ApplyBigInt(a_val, a);
    ApplyBigInt(b_val, b);
    op(a, b, ctr);
    Fact(MeasureBigInt(a) == a_val, "a was changed.");
    Fact(MeasureInteger([ctr]) == c_val, "Control qubit was changed.");
    return MeasureBigInt(b);
}

function ReverseInt(nbits: Int, x: Int) : Int {
    return Convert.BoolArrayAsInt(Reversed(Convert.IntAsBoolArray(x, nbits)));
}

// Sets qs := a1*|v1> + a2*|v2>.
// qs must be prepared in |0> state.
// Must be |a1|^2 + |a2|^2=1, v1!=v2.
// Registers are little-endian.
operation PrepareSuperposition(qs : Qubit[], a1 : Double, v1 : Int, a2 : Double, v2 : Int) : Unit is Ctl {
    let n = Length(qs);
    mutable coefs : Double[] = [0.0, size=1 <<< n];
    set coefs w/= ReverseInt(n, v1) <- a1;
    set coefs w/= ReverseInt(n, v2) <- a2;
    PreparePureStateD(coefs, qs);
}