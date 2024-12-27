/// Implementation of the Wallace Tree multiplier, presented in paper:
///   Improving the number of T gates and their spread in integer multipliers on quantum computing.
///   F. Orts, E. Filatovas, G. Ortega, J. F. SanJuan-Estrada, E. M. Garzón, 2023.
///   https://journals.aps.org/pra/abstract/10.1103/PhysRevA.107.042621
/// All numbers are unsigned integers, little-endian.

import Std.Arrays;
import Std.Diagnostics.Fact;
import QuantumArithmetic.Utils.*;

/// Wallace Tree operation.
struct WTOp {
    Name : String, // "AND", "FullAdder", "HalfAdder" or "CNOT".
    Args : Int[],  // Ids of qubits that are inputs to this operation.
}

/// Wallace Tree Circuit.
/// This circuit refers to qubits by their index in register, using the following layout:
///   qs[0..N1-1] - first input;
///   qs[N1..N1+N2-1] - second input;
///   qs[N1..N1+N2-1] - second input;
///   qs[N1+N2..2*(N1+N2)-1] - output (must be prepared in 0 state);
///   qs[2*(N1+N2)..TotalQubits-1] - ancilla qubits;
/// Ancilla qubits must be prepared in zero state, but are not reverted to zero state.
struct WTCircuit {
    N1 : Int,  // Number of qubits representing first input.
    N2 : Int,  // Number of qubits representing first input.
    TotalQubits : Int,  // Total number of qubit, inluding inputs, output and ancillas.
    Ops : WTOp[],
}


function InversePermutation(perm : Int[]) : Int[] {
    let n = Length(perm);
    mutable ans : Int[] = [0, size = n];
    for i in 0..n-1 {
        set ans w/= perm[i] <- i;
    }
    return ans;
}

function ApplyPermToOp(op : WTOp, perm : Int[]) : WTOp {
    mutable new_args: Int[] = [];
    for arg in op.Args {
        set new_args += [perm[arg]];
    }
    return new WTOp { Name = op.Name, Args = new_args };
}

/// Computes c:=a&b.
operation AndGate(a : Qubit, b : Qubit, c : Qubit) : Unit is Adj + Ctl {
    CCNOT(a, b, c);
}

/// Computes c,d=MAJ(a,b,c),a⊕b⊕c.
/// Alowed to do anything with a,b.
/// TODO: extend so we can use Wang adder (fig 5(a)).
operation FullAdder(a : Qubit, b : Qubit, c : Qubit, d : Qubit) : Unit is Adj + Ctl {
    QuantumArithmetic.GKDKH2021.QuantumFullAdder(a, b, d, c);
}


/// Computes b,c:=a⊕b,a&b.
operation HalfAdder(a : Qubit, b : Qubit, c : Qubit) : Unit is Adj + Ctl {
    CCNOT(a, b, c);
    CNOT(a, b);
}

/// Builds quantum circuit for the Wallace Tree.
/// Uses this algorithm:
/// https://github.com/fedimser/quant_comp/blob/master/arithmetic/Wallace%20Tree.ipynb
/// We need to do this in advance to know exact number of ancilla qubits.
function BuildWallaceTreeCircuit(n1 : Int, n2 : Int) : WTCircuit {
    Fact(n1 >= 2 and n2 >= 2, "Inputs must have at least 2 bits each.");

    mutable qubit_ctr = n1 + n2;
    mutable ops : WTOp[] = [];
    mutable groups : Int[][] = [[], size = n1 + n2];

    // AND array.
    for i1 in 0..n1-1 {
        for i2 in 0..n2-1 {
            let target = qubit_ctr;
            set qubit_ctr += 1;
            let level = i1 + i2;
            set ops += [new WTOp { Name = "AND", Args = [i1, n1 + i2, target] }];
            set groups w/= level <- groups[level] + [target];
        }
    }

    Message($"groups {groups}");
    Message($"ops BEFORE last addition {Length(ops)}");


    // The last layer is regular addition of 2 binary numbers.
    mutable output_bits : Int[] = [];
    for i in 0..n1 + n2-1 {
        if (Length(groups[i]) == 1) {
            set output_bits += [groups[i][0]];
        } elif (Length(groups[i]) == 2) {
            if i == n1 + n2-1 {
                // Last bit cannot overflow, so we don't need the carry bit.
                set ops += [new WTOp { Name = "CNOT", Args = [groups[i][0], groups[i][1]] }];
            } else {
                let carry_bit = qubit_ctr;
                set qubit_ctr += 1;
                set ops += [new WTOp { Name = "HalfAdder", Args = [groups[i][0], groups[i][1], carry_bit] }];
                set groups w/= i + 1 <- groups[i + 1] + [carry_bit];
            }
            set output_bits += [groups[i][1]];
        } else {
            Fact(Length(groups[i]) == 3, "Unexpected grpup length");
            let sum_bit = qubit_ctr;
            set qubit_ctr += 1;
            let carry_bit = groups[i][2];
            set ops += [new WTOp { Name = "FullAdder", Args = [groups[i][0], groups[i][1], carry_bit, sum_bit] }];
            set output_bits += [sum_bit];
            set groups w/= i + 1 <- groups[i + 1] + [carry_bit];
        }
    }
    Message($"ops AFTER last addition {Length(ops)}");


    // Remap qubit indexes so outputs are written right after inputs.
    mutable perm_before : Int[] = RangeAsIntArray(0..n1 + n2-1) + output_bits;
    for i in (n1 + n2)..(qubit_ctr-1) {
        if Arrays.IndexOf(x -> x == i, output_bits) == -1 {
            set perm_before += [i];
        }
    }
    Message($"perm_before {perm_before}");
    Fact(Length(perm_before) == qubit_ctr, "");
    let perm : Int[] = InversePermutation(perm_before);
    Message($"perm {perm}");
    Fact(Length(perm) == qubit_ctr, "");
    mutable remapped_ops : WTOp[] = [];
    for op in ops {
        set remapped_ops += [ApplyPermToOp(op, perm)];
    }

    return new WTCircuit { N1 = n1, N2 = n1, TotalQubits = qubit_ctr, Ops = remapped_ops };
}

operation ApplyWallaceTreeCircuit(circuit : WTCircuit, qs : Qubit[]) : Unit is Adj + Ctl {
    Fact(Length(qs) == circuit.TotalQubits, "Size mismatch");
    for op in circuit.Ops {
        if op.Name == "AND" {
            AndGate(qs[op.Args[0]], qs[op.Args[1]], qs[op.Args[2]]);
        } elif op.Name == "FullAdder" {
            FullAdder(qs[op.Args[0]], qs[op.Args[1]], qs[op.Args[2]], qs[op.Args[3]]);
        } elif op.Name == "HalfAdder" {
            HalfAdder(qs[op.Args[0]], qs[op.Args[1]], qs[op.Args[2]]);
        } else {
            Fact(op.Name == "CNOT", "Unexpected op: " + op.Name);
            CNOT(qs[op.Args[0]], qs[op.Args[1]]);
        }
    }
}

/// Computes C = A*B using Wallace Tree.
operation MultiplyWallaceTree(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n1 = Length(A);
    let n2 = Length(B);
    Fact(Length(C) == n1 + n2, "Size mismatch");

    let circuit : WTCircuit = BuildWallaceTreeCircuit(n1, n2);
    use result = Qubit[(n1 + n2)];
    use ancillas = Qubit[circuit.TotalQubits - 2 * (n1 + n2)];
    within {
        ApplyWallaceTreeCircuit(circuit, A + B + result + ancillas);
    } apply {
        ParallelCNOT(result, C);
    }
}


operation MultiplyWallaceTreeIrr(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit {
    let n1 = Length(A);
    let n2 = Length(B);
    Fact(Length(C) == n1 + n2, "Size mismatch");

    let circuit : WTCircuit = BuildWallaceTreeCircuit(n1, n2);
    use ancillas = Qubit[circuit.TotalQubits - 2 * (n1 + n2)];
    ApplyWallaceTreeCircuit(circuit, A + B + C + ancillas);
    ResetAll(ancillas);
}
