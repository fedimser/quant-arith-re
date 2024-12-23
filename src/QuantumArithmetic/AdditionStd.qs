/// Addition algorithms from Q# standard library, re-exported.

// Computes ys += xs modulo 2^n.
// Ref: Takahashi,Tani,Kunihiro, 2009, https://arxiv.org/abs/0910.2530
operation Add_TTK(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    Std.Arithmetic.RippleCarryTTKIncByLE(xs, ys);
}

// Computes ys += xs modulo 2^n.
// Ref: Craig Gidney, 2018, https://arxiv.org/pdf/1709.06648.pdf
operation Add_CG(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    Std.Arithmetic.RippleCarryCGIncByLE(xs, ys);
}

// Computes ys += xs modulo 2^n.
// Ref: Draper, 2000, https://arxiv.org/abs/quant-ph/0008033
operation Add_QFT(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    Std.Arithmetic.FourierTDIncByLE(xs, ys);
}

// Computes zs := xs + ys + zs[0] modulo 2^n.
// Ref: Draper,Kutin,Rains,Svore, 2004, https://arxiv.org/abs/quant-ph/0406142
operation Add_DKRS(xs : Qubit[], ys : Qubit[], zs : Qubit[]) : Unit is Adj {
    Std.Arithmetic.LookAheadDKRSAddLE(xs, ys, zs);
}
