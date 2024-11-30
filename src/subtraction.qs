namespace QuantumArithmetic {
    
    // Computes ys -= xs.
    // Ref: Thapliyal, 2016.
    // https://link.springer.com/chapter/10.1007/978-3-662-50412-3_2
    operation Subtract(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
        let ysLen = Length(ys);
        for i in 0..ysLen-1 {
            X(ys[i]);
        }
        Std.Arithmetic.RippleCarryTTKIncByLE(xs, ys);
        for i in 0..ysLen-1 {
            X(ys[i]);
        }
    }
}