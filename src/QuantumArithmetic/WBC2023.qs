import Std.Diagnostics.DumpMachine;
/// Implementation of the adder presented in paper:
/// A Higher radix architecture for quantum carry-lookahead adder
/// Wang, Baksi, Chattopadhyay, 2024.
/// https://www.nature.com/articles/s41598-023-41122-4

import Std.Diagnostics.DumpMachine;
import Std.Diagnostics.Fact;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.HigherRadix;
import QuantumArithmetic.AdditionStd.Add_CG;

// Main Add function that takes A, B, and the radix
// The first step is setup the higher radix
// Then the Gidney RCA is used
operation Add(A: Qubit[], B: Qubit[], radix: Int) : Unit is Adj {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    use ancilla = Qubit[n];

    //DEBUG
    // Message("Starting State:");
    // DumpMachine();

    // call higher radix function that returns an initial state 
    HigherRadix(A, B, ancilla, radix);


    //DEBUG
    // Message("After higher radix before addition:");
    // DumpMachine();


    // first round does not include a carry in
    first_RCA_CG(A[0..radix-1], B[0..radix-1], ancilla[0..radix-2]);

    // the rest of the groups include the carry
    for i in 1..n/radix-1 {
        RCA_CG(A[i*radix..(i+1)*radix-1], B[i*radix..(i+1)*radix-1], ancilla[i*radix-1..(i+1)*radix-2]);
    }

    // Currently error about an ancillary qubit not in state |0>
    // ResetAll(ancilla);

    // DEBUG
    DumpMachine();
    
    for i in 0..n/radix-1{
        Message($"B{i} : {B[i*radix..(i+1)*radix-1]}");
    }
    Message("final state:");

    // 00100 00000 00000
    // 100100000000000
    // 00100 00000 00000


}

operation first_RCA_CG(A: Qubit[], B: Qubit[], ancilla: Qubit[]) : Unit is Adj + Ctl {
    let alen : Int = Length(A);
    // carry_in would normally be ancilla[0], but for first group it is not needed
    within {
            ApplyAndAssuming0Target(A[0], B[0], ancilla[0]);
    } apply {
        for i in 1..alen - 2 {
            CarryForInc(ancilla[i - 1], A[i], B[i], ancilla[i]);
        }
        CNOT(ancilla[alen - 2], B[alen - 1]);
        for i in alen - 2..-1..1 {
            UncarryForInc(ancilla[i - 1], A[i], B[i], ancilla[i]);
        }
    }
    for i in 0..alen-1{
        CNOT(A[i], B[i]); 
    }
}

operation RCA_CG(A: Qubit[], B: Qubit[], ancilla: Qubit[]) : Unit is Adj + Ctl {
    let alen : Int = Length(A);
    
    for i in 0..alen - 2 {
        CarryForInc(ancilla[i], A[i], B[i], ancilla[i+1]);
    }
    CNOT(ancilla[alen - 1], B[alen - 1]);
    for i in alen - 2..-1..0 {
        UncarryForInc(ancilla[i], A[i], B[i], ancilla[i+1]);
    }
    for i in 0..alen-1{
        CNOT(A[i], B[i]); 
    }

}

/// # Summary
/// Computes carry bit for a full adder.
operation CarryForInc(carryIn : Qubit, x : Qubit, y : Qubit, carryOut : Qubit) : Unit is Adj + Ctl {
    body (...) {
        CNOT(carryIn, x);
        CNOT(carryIn, y);
        ApplyAndAssuming0Target(x, y, carryOut);
        CNOT(carryIn, carryOut);
    }
    adjoint auto;
    controlled (ctls, ...) {
        // This CarryForInc is intended to be used only in an in-place
        // ripple-carry implementation. Only such particular use case allows
        // for this simple implementation where controlled version
        // is the same as uncontrolled body.
        CarryForInc(carryIn, x, y, carryOut);
    }
    controlled adjoint auto;
}

/// # Summary
/// Uncomputes carry bit for a full adder.
operation UncarryForInc(carryIn : Qubit, x : Qubit, y : Qubit, carryOut : Qubit) : Unit is Adj + Ctl {
    body (...) {
        CNOT(carryIn, carryOut);
        Adjoint ApplyAndAssuming0Target(x, y, carryOut);
        CNOT(carryIn, x);
        //CNOT(x, y);
    }
    adjoint auto;
    controlled (ctls, ...) {
        Fact(Length(ctls) == 1, "UncarryForInc should be controlled by exactly one control qubit.");

        let ctl = ctls[0];

        CNOT(carryIn, carryOut);
        Adjoint ApplyAndAssuming0Target(x, y, carryOut);
        CCNOT(ctl, x, y); // Controlled X(ctls + [x], y);
        CNOT(carryIn, x);
        CNOT(carryIn, y);
    }
    controlled adjoint auto;
}

operation RippleCarryCGIncByLE(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    let xsLen = Length(xs);
    let ysLen = Length(ys);

    Fact(ysLen >= xsLen, "Register `ys` must be longer than register `xs`.");
    Fact(xsLen >= 1, "Registers `xs` and `ys` must contain at least one qubit.");

    if xsLen == 1 {
        if ysLen == 1 {
            CNOT(xs[0], ys[0]);
        } elif ysLen == 2 {
            HalfAdderForInc(xs[0], ys[0], ys[1]);
        }
    } else {
        use carries = Qubit[xsLen];
        within {
            ApplyAndAssuming0Target(xs[0], ys[0], carries[0]);
        } apply {
            for i in 1..xsLen - 2 {
                CarryForInc(carries[i - 1], xs[i], ys[i], carries[i]);
            }
            if xsLen == ysLen {
                within {
                    CNOT(carries[xsLen - 2], xs[xsLen - 1]);
                } apply {
                    CNOT(xs[xsLen - 1], ys[xsLen - 1]);
                }
            } else {
                FullAdderForInc(carries[xsLen - 2], xs[xsLen - 1], ys[xsLen - 1], ys[xsLen]);
            }
            for i in xsLen - 2..-1..1 {
                UncarryForInc(carries[i - 1], xs[i], ys[i], carries[i]);
            }
        }
        CNOT(xs[0], ys[0]);
    }
}

operation HalfAdderForInc(x : Qubit, y : Qubit, carryOut : Qubit) : Unit is Adj + Ctl {
    body (...) {
        CCNOT(x, y, carryOut);
        CNOT(x, y);
    }
    adjoint auto;

    controlled (ctls, ...) {
        Fact(Length(ctls) == 1, "HalfAdderForInc should be controlled by exactly one control qubit.");

        let ctl = ctls[0];
        use helper = Qubit();

        within {
            ApplyAndAssuming0Target(x, y, helper);
        } apply {
            ApplyAndAssuming0Target(ctl, helper, carryOut);
        }
        CCNOT(ctl, x, y);
    }
    controlled adjoint auto;
}

/// # Summary
/// Implements Full-adder. Adds qubit carryIn and x to qubit y and sets carryOut appropriately.
operation FullAdderForInc(carryIn : Qubit, x : Qubit, y : Qubit, carryOut : Qubit) : Unit is Adj + Ctl {
    body (...) {
        // TODO: cannot use `Carry` operation here
        CNOT(carryIn, x);
        CNOT(carryIn, y);
        CCNOT(x, y, carryOut);
        CNOT(carryIn, carryOut);
        CNOT(carryIn, x);
        CNOT(x, y);
    }
    adjoint auto;

    controlled (ctls, ...) {
        Fact(Length(ctls) == 1, "FullAdderForInc should be controlled by exactly one control qubit.");

        let ctl = ctls[0];
        use helper = Qubit();

        CarryForInc(carryIn, x, y, helper);
        CCNOT(ctl, helper, carryOut);
        Controlled UncarryForInc(ctls, (carryIn, x, y, helper));
    }
    controlled adjoint auto;
}
@Config(Adaptive)
operation ApplyAndAssuming0Target(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit is Adj {
    // NOTE: Eventually this operation will be public and intrinsic.
    body (...) {
        CCNOT(control1, control2, target);
    }
    adjoint (...) {
        H(target);
        if M(target) == One {
            Reset(target);
            CZ(control1, control2);
        }
    }
}