/// Table lookups and table functions.

import Std.Diagnostics.Fact;

/// Controlled table lookup.
operation TableLookupCtl(control : Qubit, input : Qubit[], target : Qubit[], table : BigInt[]) : Unit is Adj {
    let m = Length(input);
    let tn = Length(table);
    Fact(tn == 1 <<< m, "Table size must be 2^m.");

    if (m == 0) {
        Controlled ApplyXorInPlaceL([control], (table[0], target));
    } else {
        use anc = Qubit();
        X(input[m-1]);
        within {
            AND(control, input[m-1], anc);
        } apply {
            X(input[m-1]);
            TableLookupCtl(anc, input[0..m-2], target, table[0..tn / 2-1]);
            CNOT(control, anc);
            TableLookupCtl(anc, input[0..m-2], target, table[tn / 2..tn-1]);
        }

    }
}

/// Assigns target ⊕= table[input].
/// Uses algorithm from from https://arxiv.org/abs/1805.03662.
operation TableLookup(input : Qubit[], target : Qubit[], table : BigInt[]) : Unit is Adj + Ctl {
    body (...) {
        let m = Length(input);
        let tn = Length(table);
        X(input[m-1]);
        TableLookupCtl(input[m-1], input[0..m-2], target, table[0..tn / 2-1]);
        X(input[m-1]);
        TableLookupCtl(input[m-1], input[0..m-2], target, table[tn / 2..tn-1]);
    }
    controlled (controls, ...) {
        if (Length(controls) == 0) {
            TableLookup(input, target, table);
        } else {
            Fact(Length(controls) <= 1, "Only up to 1 control is supported.");
            TableLookupCtl(controls[0], input, target, table);
        }
    }
}

/// Computes Ans:=f(I), where I is some tabulated function.
/// f is defined by classical function f_table, such that f_table(n)=[f(0), f(1), ... f(n-1)].
/// Ans must be large enough to fit any possible result for every possible input.
/// See implementation of `Factorial` as example.
operation TableFunction(I : Qubit[], Ans : Qubit[], f_table : (Int -> BigInt[])) : Unit is Adj + Ctl {
    TableLookup(I, Ans, f_table(1 <<< Length(I)));
}

/// Computes [0!, 1!, ..., (n-1)!].
function ComputeFactorials(n : Int) : BigInt[] {
    mutable ans : BigInt[] = [1L];
    for i in 1..n-1 {
        set ans += [Std.Convert.IntAsBigInt(i) * ans[i-1]];
    }
    return ans;
}

operation Factorial(I : Qubit[], Ans : Qubit[]) : Unit is Adj + Ctl {
    TableFunction(I, Ans, ComputeFactorials);
}

export TableLookup, TableFunction, Factorial;