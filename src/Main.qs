import TestUtils;
import QuantumArithmetic.NZLS2023Test;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 1;
    let a = 196;
    let X : BigInt[]  = [1L,2L,3L,4L];
    let ans = NZLS2023Test.TestFFT(3,3,X);
    Message($"ans={ans}");
}