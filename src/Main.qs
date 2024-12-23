import TestUtils;
import QuantumArithmetic.NZLS2023;
import QuantumArithmetic.Utils;


operation RelabelBug(): Unit {
    use q = Qubit[5];
    X(q[1]); // q=2.
    Relabel(q, q[2..4]+q[0..1]);  // Shift right by 3, must get 2<<3=16.
    Message($"ans={MeasureInteger(q)}"); // prints 4.
}

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    RelabelBug();
}