namespace QuantumArithmetic { 
    // Re-export IncByLE from standard library.
    operation IncByLE(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
        Std.Arithmetic.IncByLE(xs, ys);
    }

    // TODO: implement other algorithms.
}