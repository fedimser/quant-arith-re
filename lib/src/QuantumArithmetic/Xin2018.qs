/// Implementation of half comparator circuit in:
/// Novel multi-bit quantum comparators and their applicationin image binarization https://doi.org/10.1007/s11128-019-2334-2
import Std.Diagnostics.Fact;

// CCNOT gate with positive control 
operation mixed_CCNOT(positive_control : Qubit, negative_control : Qubit, target : Qubit) : Unit is Adj + Ctl {
    within {
        X(positive_control);
    } apply {
        CCNOT(negative_control, positive_control, target);
    }
}
// a < b if ans changes, a >= b if ans stays the same
operation CompareLess(a : Qubit[], b : Qubit[], ans: Qubit) : Unit is Adj + Ctl {
    let n = Length(a);
    Fact(Length(b) == n, "Registers sizes must match.");
    if (n == 1) {
        mixed_CCNOT(a[0], b[0], ans);
    } else {
        
    use acc = Qubit();
    let acc_b = [acc] + b[1..n-1];
    within{
        for i in 0..n-1 {
            CNOT(b[i], a[i]);
        }
        for i in 1..n-1 {
            CNOT(acc_b[i], acc_b[i-1]);
        }
        CCNOT(a[0], b[0], acc);
        for i in 1..n-2 {
            mixed_CCNOT(a[i], acc_b[i-1], b[i]);
        }
    }
    apply {
        CNOT(b[n-1], ans);
        mixed_CCNOT(a[n-1], acc_b[n-2], ans);
    }
    }
}