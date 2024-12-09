import Std.Arrays.Most;
import Std.Arrays.Reversed;
import Std.Arithmetic.MAJ;

// UnMajority and Add, restores ai to Ai and ci to Ai−1 and writes si to Bi
operation UMA_2CNOT(x: Qubit, y: Qubit, z: Qubit) : Unit {
    CCNOT(x, y, z);
    CNOT(z, x);
    CNOT(x, y);
}

// UMA for better parallelism
operation UMA_3CNOT(x: Qubit, y: Qubit, z: Qubit) : Unit is Adj + Ctl {
    X(y);
    CNOT(x,y);
    CCNOT(x,y,z);
    X(y);
    CNOT(z,x);
    CNOT(z,y);
}

operation Add(A : Qubit[], B : Qubit[], Z: Qubit) : Unit is Adj + Ctl {
    let n = Length(A);
    use ancilla = Qubit();

    let slot1Qubits = [ancilla] + Most(A);
    let slot2Qubits = B;
    let slot3Qubits = A;

    for i in 0..n-1 {
        Std.Arithmetic.MAJ(slot1Qubits[i], slot2Qubits[i], slot3Qubits[i]);
    }
    CNOT(A[n-1], Z);
    // reverse order
    for i in 0..n-1 { 
        UMA_3CNOT(slot1Qubits[n-1-i], slot2Qubits[n-1-i], slot3Qubits[n-1-i]);
    }
}

operation Add_Mod2(A : Qubit[], B : Qubit[]) : Unit is Adj + Ctl {
    let n = Length(A);
    use ancilla = Qubit();
    let slot1Qubits = [ancilla] + Most(A);
    let slot2Qubits = B;
    let slot3Qubits = A;

    for i in 0..n-1 {
        Std.Arithmetic.MAJ(slot1Qubits[i], slot2Qubits[i], slot3Qubits[i]);
    }
    // reverse order
    for i in 0..n-1 { 
        UMA_3CNOT(slot1Qubits[n-1-i], slot2Qubits[n-1-i], slot3Qubits[n-1-i]);
    }
}

// operation Add_optimized(A : Qubit[], B : Qubit[], Z: Qubit) : Unit is Adj + Ctl {
//     let n = Length(A);
//     // Fact(Length(B) == n, "Registers sizes must match.");
//     // if n < 4 {
//     //     for i in 0..n-1 {
//     //         CNOT(A[i], B[i]);
//     //     }
//     //     return 
//     // }
//     use ancilla = Qubit();
//     for i in 1..n-1 {
//         CNOT(A[i], B[i]);
//     }
//     CNOT(A[1], ancilla);
//     CCNOT(A[0], B[0], ancilla);
//     CNOT(A[2], A[1]); // same time as above
//     CCNOT(B[1], ancilla, A[1]);
//     CNOT(A[3], A[2]); // same time as above
//     for i in 2..n-3 {
//         CCNOT(A[i-1], B[i], A[i]);
//         CNOT(A[i+2], A[i+1]); // same time as above
//     }

//     CCNOT(A[n-3], B[n-2], A[n-2]);
//     CNOT(A[n-1], Z); // same time as above
//     CCNOT(B[n-1], A[n-2], Z);
//     for i in 1..n-2 { // same time as above
//         X(B[i]);
//     }
//     CNOT(ancilla, B[1]);
//     for i in 2..n-1 { // same time as above
//         CNOT(A[i-1], B[i]);
//     }
//     CCNOT(A[n-3], B[n-2], A[n-2]);
//     for i in n-3..2 {   
//         CCNOT(A[i-1], B[i], A[i]);
//         CNOT(A[i+2], A[i+1]); // same time as above
//         X(B[i+1]); // same time as above
//     }
//     CCNOT(B[1], ancilla, A[1]);
//     CNOT(A[3], A[2]); // same time as above
//     X(B[2]); // same time as above

//     CCNOT(A[0], B[0], ancilla);
//     CNOT(A[2], A[1]); // same time as above
//     X(B[1]); // same time as above

//     CNOT(A[1], ancilla);
//     for i in 0..n-1 {
//         CNOT(A[i], B[i]);
//     }
// }