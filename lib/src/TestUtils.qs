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

/// Tests artihemtic operation that acts on array of qubit registers.
/// Numbers are unsigned little-endian integers.
operation TestArithmeticOp(
    op : (Qubit[][]) => Unit,
    sizes : Int[],
    vals : BigInt[]
) : BigInt[] {
    Fact(Length(sizes) == Length(vals), "sizes and vals must have the same length.");
    let n = Length(sizes);
    mutable total = 0;
    for sz in sizes {
        set total += sz;
    }
    use allQubits = Qubit[total];
    mutable regs : Qubit[][] = [];
    mutable offset = 0;
    for sz in sizes {
        set regs += [allQubits[offset..offset + sz - 1]];
        set offset += sz;
    }
    for i in 0..n - 1 {
        ApplyBigInt(vals[i], regs[i]);
    }

    op(regs);

    mutable results : BigInt[] = [];
    for i in 0..n - 1 {
        set results += [MeasureBigInt(regs[i])];
    }
    return results;
}

// Computes op(x).
operation TestUnaryOp(n : Int, x_val : BigInt, op : (Qubit[]) => Unit) : BigInt {
    use x = Qubit[n];
    ApplyBigInt(x_val, x);
    op(x);
    return MeasureBigInt(x);
}

function ReverseInt(nbits : Int, x : Int) : Int {
    return Convert.BoolArrayAsInt(Reversed(Convert.IntAsBoolArray(x, nbits)));
}

// Sets qs := a1*|v1> + a2*|v2>.
// qs must be prepared in |0> state.
// Must be |a1|^2 + |a2|^2=1, v1!=v2.
// Registers are little-endian.
operation PrepareSuperposition(qs : Qubit[], a1 : Double, v1 : Int, a2 : Double, v2 : Int) : Unit is Ctl {
    let n = Length(qs);
    mutable coefs : Double[] = [0.0, size = 1 <<< n];
    set coefs w/= ReverseInt(n, v1) <- a1;
    set coefs w/= ReverseInt(n, v2) <- a2;
    PreparePureStateD(coefs, qs);
}

export ApplyBigInt, MeasureBigInt, TestArithmeticOp, TestUnaryOp;