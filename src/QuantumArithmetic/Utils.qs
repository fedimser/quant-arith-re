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

/// Rotates qubits right.
/// Uses n-1 SWAP gates (and no other gates). Has depth at most 2.
/// Idea from JHHA2016 paper (https://arxiv.org/abs/1608.01228).
operation RotateRight(qubits : Qubit[]) : Unit is Adj + Ctl {
    let k : Int = Length(qubits);
    let k1 : Int = k / 2;
    for i in 0..k1-1 {
        SWAP(qubits[i], qubits[k-1-i]);
    }
    for i in 0..k1-2 + (k % 2) {
        SWAP(qubits[i], qubits[k-2-i]);
    }
}

/// Computes: qubits[i] := qubits[P[i]] for i=0..n-1.
/// Uses at most n-1 SWAP gates (and no other gates). Has depth at most 2.
operation ApplyPermutationWithSWAPs(qubits: Qubit[], P: Int[]): Unit is Ctl + Adj{
    let n = Length(qubits);
    Fact(Length(qubits) == n, "Size mismatch.");

    // Split permutation into cycles, rotate along each cycle.
    
}