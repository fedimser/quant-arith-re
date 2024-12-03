/// Implementation of addition and subtraction presented in paper:
///   Quantum full adder and subtractor,
///   Kai-Wen Cheng and Chien-Cheng Tseng, 2002.

namespace QuantumArithmetic {
    import Std.Diagnostics.Fact;
    
    // 1-bit quantum Full Adder.
    operation QFA_CT(carry_im1: Qubit, a_i: Qubit, b_i: Qubit, carry_i: Qubit): Unit is Adj + Ctl {
        CCNOT(a_i, b_i, carry_i);
        CNOT(a_i, b_i);
        CCNOT(carry_im1, b_i, carry_i);
        CNOT(carry_im1, b_i);
    }

    // Computes (a,b) = (a, a+b).
    operation Add_CT(a : Qubit[], b : Qubit[]): Unit {
        let n = Length(a);
        Fact(Length(b) == n, "Registers sizes must match.");
        use carry = Qubit[n+1];
        for i in 0..n-1 {
            QFA_CT(carry[i], a[i], b[i], carry[i+1]);
        }
        ResetAll(carry);
    }

    // 1-bit quantum full subtractor.    
    operation QFS_CT(borrow_im1: Qubit, a_i: Qubit, b_i: Qubit, borrow_i: Qubit): Unit is Adj + Ctl {
        CNOT(borrow_im1, b_i);
        X(a_i);
        CCNOT(a_i, b_i, borrow_i);
        CNOT(borrow_im1, b_i);
        CCNOT(borrow_im1, b_i, borrow_i);
        X(a_i);
        CNOT(a_i, b_i);
        CNOT(borrow_im1, b_i);
    }

    // Computes (a,b) = (a, a-b).
    operation Subtract_CT(a : Qubit[], b : Qubit[]): Unit {
        let n = Length(a);
        Fact(Length(b) == n, "Registers sizes must match.");
        use brw = Qubit[n+1];
        for i in 0..n-1 {
            QFS_CT(brw[i], a[i], b[i], brw[i+1]);
        }
        ResetAll(brw);
    }
}
