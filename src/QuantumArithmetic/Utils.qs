/// Common functions and operations.

import Std.Diagnostics.Fact;
import Std.Math;

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

/// Computes ⌈a/b⌉. 
function DivCeil(a: Int, b:Int) : Int {
    return ((a + b - 1) / b); 
}

/// Applies X for each qubit in register.
operation ParallelX(qubits : Qubit[]) : Unit is Ctl + Adj {
    ApplyToEachCA(X, qubits);
}

/// Applies CNOT between two registers.
operation ParallelCNOT(controls : Qubit[], targets : Qubit[]) : Unit is Ctl + Adj {
    let n : Int = Length(controls);
    Fact(Length(targets) == n, "Size mismatch.");
    for i in 0..n-1 {
        CNOT(controls[i], targets[i]);
    }
}

/// Applies SWAP between two registers.
operation ParallelSWAP(controls : Qubit[], targets : Qubit[]) : Unit is Ctl + Adj {
    let n : Int = Length(controls);
    Fact(Length(targets) == n, "Size mismatch.");
    for i in 0..n-1 {
        SWAP(controls[i], targets[i]);
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
            set ans += [(cycle[i], cycle[k-1-i])];
        }
        for i in 0..k1-2 + (k % 2) {
            set ans += [(cycle[i], cycle[k-2-i])];
        }
    }
    return ans;
}


/// Equivalent to SWAP, but doesn't apply quantum gates.
operation SWAPViaRelabel(q1 : Qubit, q2 : Qubit) : Unit is Adj {
    Relabel([q1, q2], [q2, q1]);
}

/// Computes: qubits[i] := qubits[P[i]] for i=0..n-1.
/// Doesn't apply any quantum gates.
operation ApplyPermutation(qubits : Qubit[], P : Int[]) : Unit is Adj {
    Fact(Length(P) == Length(qubits), "Size mismatch.");
    Relabel(qubits, Std.Arrays.Mapped(i -> qubits[i], P));
}

/// Rotates qubits of P right by 1.
operation RotateRight(P : Qubit[]) : Unit is Adj + Ctl {
    let k : Int = Length(P);
    let k1 : Int = k / 2;
    for i in 0..k1-1 {
        SWAP(P[i], P[k-1-i]);
    }
    for i in 0..k1-2 + (k % 2) {
        SWAP(P[i], P[k-2-i]);
    }
}

/// Rotates qubits of P left by 1.
operation RotateLeft(P : Qubit[]) : Unit is Adj + Ctl {
    Adjoint RotateRight(P);
}

/// Computes ys -= xs.
operation Subtract(xs : Qubit[], ys : Qubit[]) : Unit is Adj + Ctl {
    ParallelX(ys);
    Std.Arithmetic.RippleCarryTTKIncByLE(xs, ys);
    ParallelX(ys);
}

/// Rearranges qubits into n1xn2 2-dimensional array.
function Rearrange2D(q : Qubit[], n1 : Int, n2 : Int) : Qubit[][] {
    Fact(Length(q) == n1 * n2, "Size mismatch in Rearrange2D.");
    mutable ans : Qubit[][] = [];
    for i in 0..n1-1 {
        set ans += [q[i * n2..(i + 1) * n2-1]];
    }
    return ans;
}

/// Computes a^-1 modulo N.
function ModInv(a : BigInt, N : BigInt) : BigInt {
    Fact(Math.IsCoprimeL(a, N), "a and N must be coprime.");
    let (a_inv, unused_v) = Math.ExtendedGreatestCommonDivisorL(a, N);
    let a_inv : BigInt = ((a_inv % N) + N) % N;
    Fact(1L <= a_inv and a_inv < N, "a_inv out of bound");
    Fact((a * a_inv) % N == 1L, "a_inv is computed incorrectly");
    return a_inv;
}

/// Computes [(a^(2^i))%N for i in 0..n-1].
function ComputeSequentialSquares(a : BigInt, N : BigInt, n : Int) : BigInt[] {
    mutable ans : BigInt[] = [((a % N) + N) % N];
    for i in 1..n-1 {
        set ans += [(ans[i-1] * ans[i-1]) % N];
    }
    return ans;
}

export RotateRight, RotateLeft, Subtract;