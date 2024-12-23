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
function RangeAsIntArray(range : Range) : Int[] {
    return Std.Arrays.MappedOverRange(i -> i, range);
}

/// Computes: qubits[i] := qubits[P[i]] for i=0..n-1.
/// Doesn't apply any quantum gates.
operation ApplyPermutation(qubits : Qubit[], P : Int[]) : Unit is Adj {
    Fact(Length(P) == Length(qubits), "Size mismatch.");
    let newOrder = Std.Arrays.Mapped(i -> qubits[i], P);
    Relabel(qubits, newOrder);
}

/// For a permutation, finds all cycles with length >= 2.
function GetCycles(P : Int[]) : Int[][] {
    let n = Length(P);
    mutable used : Bool[] = [false, size = n];
    mutable ans : Int[][] = [];
    for i in 0..n-1 {
        mutable j : Int = i;
        mutable cycle : Int[] = [];
        while (not used[j]) {
            set cycle += [j];
            set used w/= j <- true;  // used[j]=true
            set j = P[j];
        }
        if (Length(cycle) >= 2) {
            set ans += [cycle];
        }
    }
    return ans;
}

/// Computes: qubits[i] := qubits[P[i]] for i=0..n-1.
/// Uses at most n-1 SWAP gates (and no other gates). Has depth at most 2.
/// Uses a technique from JHHA2016.
operation ApplyPermutationUsingSWAPs(qubits : Qubit[], P : Int[]) : Unit is Ctl + Adj {
    let n = Length(qubits);
    Fact(Length(P) == n, "Size mismatch.");

    // Split permutation into cycles, rotate along each cycle.
    let cycles = GetCycles(P);
    for cycle in cycles {
        let k : Int = Length(cycle);
        let k1 : Int = k / 2;
        for i in 0..k1-1 {
            SWAP(qubits[cycle[i]], qubits[cycle[k-1-i]]);
        }
        for i in 0..k1-2 + (k % 2) {
            SWAP(qubits[cycle[i]], qubits[cycle[k-2-i]]);
        }
    }
}