/// Implementation of the Wallace Tree multiplier, presented in paper:
///   Improving the number of T gates and their spread in integer multipliers on quantum computing.
///   F. Orts, E. Filatovas, G. Ortega, J. F. SanJuan-Estrada, E. M. Garzón, 2023.
///   https://journals.aps.org/pra/abstract/10.1103/PhysRevA.107.042621
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;
import QuantumArithmetic.Utils.ParallelCNOT;

struct Operation {
    Name : String,
    Args : Int[],
}

struct WallaceTreeCircuit {
    N1 : Int,
    N2 : Int,
    TotalQubits : Int,
    Ops : Operation[],
}

/// https://github.com/fedimser/quant_comp/blob/master/arithmetic/Wallace%20Tree.ipynb
function BuildWallaceTreeCircuit(n1 : Int, n2 : Int) : WallaceTreeCircuit {
    return new WallaceTreeCircuit { N1 = n1, N2 = n1, TotalQubits = 2 * (n1 + n2), Ops = [] };
}

operation ApplyWallaceTreeCircuit(circuit : WallaceTreeCircuit, qs : Qubit[]) : Unit is Adj + Ctl {
    Fact(Length(qs) == circuit.TotalQubits, "Size mismatch")
}

/// Computes C = A*B using Wallace Tree.
operation MultiplyWallaceTree(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit is Adj + Ctl {
    let n1 = Length(A);
    let n2 = Length(B);
    Fact(Length(C) == n1 + n2, "Size mismatch");

    let circuit = BuildWallaceTreeCircuit(n1, n2);
    use result = Qubit[(n1 + n2)];
    use ancillas = Qubit[circuit.TotalQubits - 2 * (n1 + n2)];
    within {
        ApplyWallaceTreeCircuit(circuit, A + B + result + ancillas);
    } apply {
        ParallelCNOT(result, C);
    }
}
