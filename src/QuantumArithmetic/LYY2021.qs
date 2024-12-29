/// Implementation of operations presented in paper:
///   CNOT-count optimized quantum circuit of the Shor’s algorithm
///   Xia Liu, Huan Yang, Li Yang, 2021.
///   https://arxiv.org/abs/2112.11358
/// All numbers are unsigned integers, little-endian.

import Std.Arithmetic.IncByLUsingIncByLE;
import Std.Diagnostics.Fact;
import Std.Math.*;

import QuantumArithmetic.CDKM2004;


/// Computes B+=A modulo 2^n.
operation Add(A: Qubit[], B: Qubit[]) : Unit is Adj + Ctl {
    CDKM2004.Add(A, B);
}

/// Computes B+=A modulo 2^n.
operation AddConstant(A: BigInt, B: Qubit[]) : Unit is Adj + Ctl {
    IncByLUsingIncByLE(Add, A, B);
}

/// Computes B+=ctrl*A modulo 2^n.
operation CtrlAdd(ctrl: Qubit, A: Qubit[], B: Qubit[]) : Unit is Adj + Ctl{
    Controlled Add([ctrl], (A, B));
}

/// Computes B+=ctrl*A modulo 2^n.
operation CtrlAddConstant(ctrl: Qubit, A: BigInt, B: Qubit[]) : Unit is Adj + Ctl{
    let n = Length(B);
    if A != 0L {
        let j = TrailingZeroCountL(A);
        use Atmp = Qubit[n - j];
        within {
            Controlled ApplyXorInPlaceL([ctrl], (A>>>j, Atmp));
        } apply {
            Add(Atmp, B[j...]);
        }
    }
}

operation Compare(): Unit is Adj + Ctl{
}

operation CompareByConst(): Unit is Adj + Ctl{
}

operation CtrlCompare(ctrl: Qubit): Unit is Adj + Ctl{
}

operation AddMod(): Unit is Adj + Ctl{
}

operation CtrlAddMod(ctrl: Qubit): Unit is Adj + Ctl{
}

operation LeftShift(): Unit is Adj + Ctl{
}

operation RightShift(): Unit is Adj + Ctl{
}