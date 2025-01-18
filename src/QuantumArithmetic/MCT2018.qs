/// Square Root algorithm, presented in the paper:
///   T-count and Qubit Optimized Quantum Circuit Design of the Non-Restoring Square Root Algorithm
///   Edgard Muñoz-Coreas, Himanshu Thapliyal, 2018.
///   https://arxiv.org/abs/1712.08254
/// All numbers are unsigned integers, little-endian.
import Std.Diagnostics.Fact;
import QuantumArithmetic.Utils.DivCeil;

// Computes ys-=xs if ctrl=1, and ys+=xs if ctrl=0.
operation AddSub(ctrl : Qubit, xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    let config = new QuantumArithmetic.TMVH2019.Config { Adder = Std.Arithmetic.RippleCarryCGIncByLE };
    QuantumArithmetic.TMVH2019.AddSub(ctrl, xs, ys, config);
}

// Computes ys+=xs if ctrl=1, does nothing if ctrl=0.
operation CtrlAdd(ctrl : Qubit, xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    Controlled Std.Arithmetic.RippleCarryCGIncByLE([ctrl], (xs, ys));
}

/// Computes R;Ans = R-Sqrt(R)^2;Sqrt(R).
/// R and Ans must be of the same size.
/// This is the implementation from the paper, but it is incorrect when the
/// highest bit of R is 1.
operation SquareRootInternal(R : Qubit[], Ans : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(R);
    Fact(n % 2 == 0, "n must be even");
    Fact(n >= 4, "n is too small");
    Fact(Length(Ans) == n, "Size mismatch");
    let m = n / 2;
    use z = Qubit();
    let F = Ans[n-2..n-1] + Ans[0..n-3];

    X(F[0]); // Set F:=1.

    // Part 1: Initial Substraction.
    X(R[n-2]); // Step 1.
    CNOT(R[n-2], R[n-1]);
    CNOT(R[n-1], F[1]);
    X(R[n-1]);
    CNOT(R[n-1], z);
    CNOT(R[n-1], F[2]);
    X(R[n-1]);
    AddSub(z, F[0..3], R[n-4..n-1]);

    // Part 2: Conditional Addition or Subtraction.
    for i in 2..m-1 {
        X(z);
        CNOT(z, F[1]);
        X(z);
        CNOT(F[2], z);
        CNOT(R[n-1], F[1]);
        X(R[n-1]);
        CNOT(R[n-1], z);
        CNOT(R[n-1], F[i + 1]);
        X(R[n-1]);
        for j in i + 1..-1..3 {
            SWAP(F[j], F[j-1]);
        }
        AddSub(z, F[0..2 * i + 1], R[n-2 * i-2..n-1]);
    }

    // Part 3: Remainder Restoration.
    X(z);
    CNOT(z, F[1]);
    X(z);
    CNOT(F[2], z);
    X(R[n-1]);
    CNOT(R[n-1], z);
    CNOT(R[n-1], F[m + 1]);
    X(R[n-1]);
    X(z);
    CtrlAdd(z, F, R);
    X(z);
    for j in m + 1..-1..3 {
        SWAP(F[j], F[j-1]);
    }
    CNOT(F[2], z);


    X(F[0]);
}

/// Computes R;Ans = R-Sqrt(R)^2;Sqrt(R).
/// R can be of any size.
/// Must be Length(Ans)>=⌈Length(R)/2⌉.
/// Ans must be prepared in zero state.
operation SquareRoot(R : Qubit[], Ans : Qubit[]) : Unit {
    let n = Length(R);
    Fact(Length(Ans) >= DivCeil(n, 2), "Ans is to small.");
    if (n == 1) {
        SWAP(R[0], Ans[0]);
    } else {
        // Add minimal necessary padding, so R has even length and its highest
        // bit is zero.
        let pad_R_size = 2 -(n % 2);
        use pad_R = Qubit[pad_R_size];
        if (Length(Ans) > n + pad_R_size) {
            SquareRootInternal(R + pad_R, Ans[0..n + pad_R_size-1]);
        } else {
            use pad_Ans = Qubit[n + pad_R_size-Length(Ans)];
            SquareRootInternal(R + pad_R, Ans + pad_Ans);
        }
    }
}

export SquareRoot;