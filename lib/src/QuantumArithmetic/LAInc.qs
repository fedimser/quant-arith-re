/// Low-ancilla incrementer circuit.


function Log2(x : Int) : Double {
    return Std.Math.Log(Std.Convert.IntAsDouble(x)) / Std.Math.LogOf2();
}

/// Computes ans := CTO(x), where CTO(x) is number of trailing (least
/// significant) "1" bits in register x before first zero bit. CTO(0)=0.
/// ans must be prepared in zero state.
operation CountTrailingOnes(x : Qubit[], ans : Qubit[]) : Unit is Ctl + Adj {
    body (...) {
        Controlled CountTrailingOnes([], (x, ans));
    }
    controlled (ctrl, ...) {
        let x_len = Length(x);
        let ctrl_len = Length(ctrl);
        if ctrl_len >= 2 {
            use anc = Qubit();
            within {
                AND(ctrl[0], ctrl[1], anc);
            } apply {
                Controlled CountTrailingOnes([anc] + ctrl[2..ctrl_len-1], (x, ans));
            }
        } elif (x_len == 1 and ctrl_len == 0) {
            CNOT(x[0], ans[0]);
        } elif (x_len == 1 and ctrl_len == 1) {
            CCNOT(ctrl[0], x[0], ans[0]);
        } elif (x_len == 2 and ctrl_len == 0) {
            X(x[1]);
            CCNOT(x[0], x[1], ans[0]);
            X(x[1]);
            CCNOT(x[0], x[1], ans[1]);
        } elif (x_len == 2 and ctrl_len == 1) {
            use x0 = Qubit();
            within {
                AND(ctrl[0], x[0], x0);
            } apply {
                X(x[1]);
                CCNOT(x0, x[1], ans[0]);
                X(x[1]);
                CCNOT(x0, x[1], ans[1]);
            }
        } else {
            let n : Int = Std.Math.Ceiling(Log2(x_len));
            let x_low = x[0..(1 <<< (n - 1))-1];
            let x_high = x[(1 <<< (n - 1))..x_len-1];
            if (x_len == 1 <<< n) {
                Std.Diagnostics.Fact(Length(ans) >= n + 1, "ans too small");
                Controlled CountTrailingOnes(ctrl, (x_low, ans[0..n-1]));
                Controlled CountTrailingOnes(ctrl + [ans[n-1]], (x_high, ans[0..n-2] + [ans[n]]));
                Controlled CNOT(ctrl, (ans[n], ans[n-1]));
            } else {
                Std.Diagnostics.Fact(Length(ans) >= n, "ans too small");
                Controlled CountTrailingOnes(ctrl, (x_low, ans[0..n-1]));
                Controlled CountTrailingOnes(ctrl + [ans[n-1]], (x_high, ans[0..n-2]));
            }
        }
    }
}

/// Flips first `ctr` bits in `target`.
/// If `ctr==0`, does nothing.
/// If `ctr==Length(target)`, flips all bits.
/// If `ctr>Length(target)`, behavior is undefined.
operation FlipFirst(target : Qubit[], ctr : Qubit[]) : Unit is Ctl + Adj {
    let target_len = Length(target);
    let ctr_len = Length(ctr);
    let n = Std.Math.Floor(Log2(target_len)) + 1;
    if (ctr_len > n) {
        // Counter too large, ignore highest qubits.
        FlipFirst(target, ctr[0..n-1]);
    } elif (ctr_len < n) {
        // Counter too small, can only affect prefix of target.
        FlipFirst(target[0..(1 <<< ctr_len)-2], ctr);
    } elif (target_len == 1) {
        CNOT(ctr[0], target[0]);
    } elif (target_len == 2) {
        CNOT(ctr[0], target[0]);
        CNOT(ctr[1], target[0]);
        CNOT(ctr[1], target[1]);
    } else {
        Std.Diagnostics.Fact(ctr_len == n, "");
        Std.Diagnostics.Fact(target_len >= (1 <<< (n - 1)), "");
        let target_low : Qubit[] = target[0..(1 <<< (n - 1))-1];
        let target_high : Qubit[] = target[(1 <<< (n - 1))..target_len-1];

        Controlled ApplyToEachCA([ctr[n-1]], (X, target_low));
        if (Length(target_high) > 0) {
            Controlled FlipFirst([ctr[n-1]], (target_high, ctr[0..n-2]));
        }
        if (Length(target_low) > 1) {
            X(ctr[n-1]);
            Controlled FlipFirst([ctr[n-1]], (target_low[0..Length(target_low)-2], ctr[0..n-2]));
            X(ctr[n-1]);
        }
    }
}

// Flips target if x==y.
operation FlipIfEqual(x : Qubit[], y : BigInt, target : Qubit) : Unit is Ctl + Adj {
    let y_bits = Std.Convert.BigIntAsBoolArray(y, Length(x));
    within {
        ApplyPauliFromBitString(PauliX, false, y_bits, x);
    } apply {
        Controlled X(x, (target));
    }
}

// Increments register x.
operation IncrementByFlip(x : Qubit[]) : Unit is Adj {
    use ctr = Qubit[Std.Math.Floor(Log2(Length(x) + 1)) + 1];
    use carry = Qubit();
    CountTrailingOnes(x, ctr);
    QuantumArithmetic.ConstAdder.AddConstant(1L, ctr);
    FlipFirst(x + [carry], ctr);
    QuantumArithmetic.ConstAdder.AddConstant(-1L, ctr);

    // Uncompute carry.
    // We know that carry=1 iff ctr=Length(x).
    FlipIfEqual(ctr, Std.Convert.IntAsBigInt(Length(x)), carry);

    // Uncompute ctr.
    ApplyToEachCA(X, x);
    Adjoint CountTrailingOnes(x, ctr);
    ApplyToEachCA(X, x);
}