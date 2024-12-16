import TestUtils;
import QuantumArithmetic.JHHA2016;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 8;
    let a = 196;
    let ans = TestUtils.UnaryOpInPlace(n, a, JHHA2016.RotateRight);
    Message($"ans={ans}");
}