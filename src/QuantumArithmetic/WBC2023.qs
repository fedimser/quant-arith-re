/// Implementation of the adder presented in paper:
/// A Higher radix architecture for quantum carry-lookahead adder
/// Wang, Baksi, Chattopadhyay, 2024.
/// https://www.nature.com/articles/s41598-023-41122-4
/// The paper uses the Gidney 2008 RCA which is implemented in 
/// Std.Arithmetic.RippleCarryCGAddByLE
///
/// NOTE: This implementation varies from the paper by being an
/// out of place adder, all CCNOTs are paired and use Gidney decomposition,
/// and 
///
/// All numbers are unsigned integers, little-endian.

import Std.Diagnostics.Fact;
import QuantumArithmetic.HigherRadixUtils.HigherRadix.computeCarryHigherRadix;
import Std.Math.Ceiling;
import Std.Convert.IntAsDouble;
import QuantumArithmetic.Utils;

/// Computes Z=A+B modulo 2^n using the provided radix
/// This is the default which uses Gidney 2008 RCA
operation Add(A: Qubit[], B: Qubit[], Z: Qubit[], radix: Int) : Unit is Adj {
    AddWithOp(A, B, Z, radix, Std.Arithmetic.RippleCarryCGAddLE);
}

/// Computes Z=A+B modulo 2^n using the provided radix.
/// This allows the user to pass in the adder operation.
/// The adder operation computes Z:=A+B+Z[0] where Z[0] is the carry in qubit.
operation AddWithOp(A: Qubit[], B: Qubit[], Z: Qubit[], radix: Int, adder_op: (Qubit[], Qubit[], Qubit[]) => Unit is Adj) : Unit is Adj {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    // determine the number of groups
    let num_groups : Int = Ceiling(IntAsDouble(Length(B))/IntAsDouble(radix))-1;

    // calculate carry bits and store them in Z[0] for each group 
    computeCarryHigherRadix(A, B, Z[radix..radix..num_groups*radix], radix, num_groups);

    // Perform Gidney's RCA  from Q# Std library on groups
    for i in 0..num_groups-1 {
        adder_op(A[i*radix..(i+1)*radix-1], B[i*radix..(i+1)*radix-1], Z[i*radix..(i+1)*radix-1]);
    }

    adder_op(A[num_groups*radix...], B[num_groups*radix...], Z[num_groups*radix...]);
}

/// Computes Z=A+B modulo 2^n using the provided radix
/// This allows the user to pass the adder operation.
/// The adder operation computes Z:=A+B+c_in where c_in is a single qubit.
operation AddWithCarry(A: Qubit[], B: Qubit[], Z: Qubit[], radix: Int, adder_op: (Qubit[], Qubit[], Qubit[], Qubit) => Unit is Adj) : Unit is Adj {
    let n : Int = Length(A);
    Fact(Length(B) == n, "Register sizes must match.");

    // determine the number of groups
    let num_groups : Int = Ceiling(IntAsDouble(Length(B))/IntAsDouble(radix))-1;

    // get carry bits for all groups including |0> for the first group
    use carry_bits = Qubit[num_groups+1];
    use temp_Z = Qubit[Length(Z)];

    within{

        // calculate carry bits and store them in Z[0] for each group 
        computeCarryHigherRadix(A, B, carry_bits[1...], radix, num_groups);

        // Perform Gidney's RCA  from Q# Std library on groups
        for i in 0..num_groups-1 {
            adder_op(A[i*radix..(i+1)*radix-1], B[i*radix..(i+1)*radix-1], temp_Z[i*radix..(i+1)*radix-1], carry_bits[i]);
        }

        // Perform Gidney's RCA from Q# Std library on greatest signifcant bits
        adder_op(A[num_groups*radix...], B[num_groups*radix...], temp_Z[num_groups*radix...], carry_bits[num_groups]);

    } 
    apply { 
        Utils.ParallelCNOT(temp_Z, Z);
    }

}

/// This acts as a Gidney Logical AND which uses 4 T gates 
operation LogicalAND(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit is Adj {
    body (...) {
        CCNOT(control1, control2, target);
    }
    adjoint (...) {
        H(target);
        if M(target) == One {
            Reset(target);
            CZ(control1, control2);
        }
    }
}

/// This CCNOT uses the deomposition Method 3 from the paper for Unpaired CCNOTs
/// This results in 7 T gates for decomposition
operation UnpairedCCNOT(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit is Adj {
    body (...) {
        CCNOT(control1, control2, target);
    }
    adjoint (...) {
        H(target);
        T(target);
        T(control2);
        Adjoint T(control1);
        CNOT(control1, control2);
        CNOT(target, control1);
        Adjoint T(control1);
        CNOT(control2, target);
        CNOT(control2, control1);
        T(target);
        Adjoint T(control1);
        Adjoint T(control2);
        CNOT(target, control1);
        S(control1);
        CNOT(control2, target);
        CNOT(control1, control2);
        H(target);
    }
}