// Common functions and operations.

import Std.Diagnostics.Fact;

// Computes Floor(Log2(n)).
function FloorLog2(n : BigInt) : Int {
    mutable x : BigInt = n;
    mutable ans : Int = 0;
    while (x > 1L) {
        set ans += 1;
        set x = x >>> 1;
    }
    return ans;
}

// Applies CNOT between two registers.
operation ParallelCNOT(controls: Qubit[], targets: Qubit[]) : Unit is Ctl + Adj{
    let n: Int = Length(controls);
    Fact(Length(targets) == n, "Size mismatch."); 
    for i in 0..n-1 {
        CNOT(controls[i], targets[i]);
    }
}