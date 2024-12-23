/// Common functions and operations.

import Std.Diagnostics.Fact;

/// Computes Floor(Log2(n)).
function FloorLog2(n : BigInt) : Int {
    mutable x : BigInt = n;
    mutable ans : Int = 0;
    while (x > 1L) {
        set ans += 1;
        set x = x >>> 1;
    }
    return ans;
}

/// Applies CNOT between two registers.
operation ParallelCNOT(controls : Qubit[], targets : Qubit[]) : Unit is Ctl + Adj {
    let n : Int = Length(controls);
    Fact(Length(targets) == n, "Size mismatch.");
    for i in 0..n-1 {
        CNOT(controls[i], targets[i]);
    }
}

// Converts Range to Int array.
function RangeAsIntArray(range: Range): Int[] {
    return Std.Arrays.MappedOverRange(i -> i, range);
}

/// Computes: qubits[i] := qubits[P[i]] for i=0..n-1.
/// Doesn't apply any quantum gates.
operation ApplyPermutation(qubits : Qubit[], P : Int[]) : Unit is Adj {
    Fact(Length(P) == Length(qubits), "Size mismatch.");
    let newOrder = Std.Arrays.Mapped(i -> qubits[i], P);
    Relabel(qubits, newOrder);
}