import TestUtils;
import QuantumArithmetic.NZLS2023;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 1;
    let a = 196;
    let ans = TestUtils.TestMultiply(n, 1L,1L, NZLS2023.MultiplyTextbook);
    Message($"ans={ans}");
}