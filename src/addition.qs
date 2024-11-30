namespace QuantumArithmetic { 
    // https://arxiv.org/abs/0910.2530
    operation Add_RippleCarryTTK(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
        Std.Arithmetic.RippleCarryTTKIncByLE(xs, ys);
    }

    // TODO: implement other algorithms.
}