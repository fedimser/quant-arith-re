import Std.Diagnostics.DumpRegister;
/// Implementation of the adder presented in paper:
/// A Higher radix architecture for quantum carry-lookahead adder
/// Wang, Baksi, Chattopadhyay, 2024.
/// https://www.nature.com/articles/s41598-023-41122-4
// The paper uses the Gidney 2008 RCA which is implemented in 
// Std.Arithmetic.RippleCarryCGIncByLE and Std.Arithmetic.RippleCarryCGAddByLE
/// This file uses some helpers copied from Std.ArithmeticUtils.

import Std.Diagnostics.DumpMachine;
import Std.Diagnostics.Fact;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.computeCarryHigherRadix;
import Std.Math.Ceiling;
import Std.Math.MinI;
import Std.Convert.IntAsDouble;
import Std.Arrays.Tail;


operation Add(A: Qubit[], B: Qubit[], Z: Qubit[], radix: Int) : Unit is Adj {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");


    // determine the number of groups
    let num_groups : Int = Ceiling(IntAsDouble(Length(B))/IntAsDouble(radix))-1;

    // calculate carry bits and store them in Z[0] for each group 
    computeCarryHigherRadix(A, B, Z[radix..radix..num_groups*radix], radix, num_groups);

    // Perform Gidney's RCA  from Q# Std library on groups
    for i in 0..num_groups-1 {
        RippleCarryCGAddLE(A[i*radix..(i+1)*radix-1], B[i*radix..(i+1)*radix-1], Z[i*radix..(i+1)*radix-1]);
    }

    // Perform Gidney's RCA from Q# Std library on greatest signifcant bits
    RippleCarryCGAddLE(A[num_groups*radix...], B[num_groups*radix...], Z[num_groups*radix...]);

}

// copied from Std.Arithmetic
operation RippleCarryCGAddLE(xs : Qubit[], ys : Qubit[], zs : Qubit[]) : Unit is Adj {
    let xsLen = Length(xs);
    let zsLen = Length(zs);
    Fact(Length(ys) == xsLen, "Registers `xs` and `ys` must be of same length.");
    Fact(zsLen >= xsLen, "Register `zs` must be no shorter than register `xs`.");

    // Since zs is zero-initialized, its bits at indexes higher than
    // xsLen remain unused as there will be no carry into them.
    let top = MinI(zsLen - 2, xsLen - 1);
    for k in 0..top {
        FullAdder(zs[k], xs[k], ys[k], zs[k + 1]);
    }

    if xsLen > 0 and xsLen == zsLen {
        CNOT(Tail(xs), Tail(zs));
        CNOT(Tail(ys), Tail(zs));
    }
}

// copied from Std.Arithmetic_Utils
// Computes carryOut := carryIn + x + y
operation FullAdder(carryIn : Qubit, x : Qubit, y : Qubit, carryOut : Qubit) : Unit is Adj {
    CNOT(x, y);
    CNOT(x, carryIn);
    CCNOT(y, carryIn, carryOut);
    CNOT(x, y);
    CNOT(x, carryOut);
    CNOT(y, carryIn);
}


/// from Std.ArithmeticUtils
@Config(Adaptive)
operation ApplyAndAssuming0Target(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit is Adj {
    // NOTE: Eventually this operation will be public and intrinsic.
    body (...) {
        CCNOT(control1, control2, target);
    }
    adjoint (...) {
        CCNOT(control1, control2, target);
    }
}
