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

/// Applies X for each qubit in register.
operation ParallelX(qubits: Qubit[]) : Unit is Ctl + Adj {
    for q in qubits {
        X(q);
    }
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

/// Decomposes permutation into swaps.
/// Result will have at most n-1 swaps and depth at most 2.
/// Uses a technique from JHHA2016 paper (https://arxiv.org/abs/1608.01228).
function PermutationToSwaps(P : Int[]) : (Int, Int)[] {
    mutable ans : (Int, Int)[] = [];
    let cycles = GetCycles(P);
    for cycle in cycles {
        let k : Int = Length(cycle);
        let k1 : Int = k / 2;
        for i in 0..k1-1 {
            set ans+=[(cycle[i], cycle[k-1-i])];
        }
        for i in 0..k1-2 + (k % 2) {
            set ans+=[(cycle[i], cycle[k-2-i])];
        }
    }
    return ans;
}


/// Equivalent to SWAP, but doesn't apply quantum gates.
operation SWAPViaRelabel(q1: Qubit, q2:Qubit): Unit is Adj {
    Relabel([q1, q2], [q2, q1]);
}

/// Computes: qubits[i] := qubits[P[i]] for i=0..n-1.
/// Doesn't apply any quantum gates.
operation ApplyPermutation(qubits : Qubit[], P : Int[]) : Unit is Adj {
    Fact(Length(P) == Length(qubits), "Size mismatch.");
    
    // This line should work, but it doesn't because of Q# bug:
    //   `Relabel(qubits, Std.Arrays.Mapped(i -> qubits[i], P));`
    // Because of that, we temporarily decompose permutation into swaps, and 
    // apply swaps using 2-qubit Relabels.

    for (i,j) in PermutationToSwaps(P) {
        SWAPViaRelabel(qubits[i], qubits[j]);
    }
}

/// Rearranges qubits into n1xn2 2-dimensional array.
function Rearrange2D(q: Qubit[], n1: Int, n2: Int) : Qubit[][] {
    Fact(Length(q) == n1 * n2, "Size mismatch in Rearrange2D.");
    mutable ans: Qubit[][] = [];
    for i in 0..n1-1 {
        set ans += [q[i*n2..(i+1)*n2-1]];
    }
    return ans;
}