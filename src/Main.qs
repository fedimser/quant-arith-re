import TestUtils.*;
import QuantumArithmetic.CG2019;
import QuantumArithmetic.Utils;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 8;
    let a = 21L;
    let b = 23L;
    let ans = TestMultiply(n, a, b, CG2019.MultiplyKaratsuba);
    
    Message($"ans={ans}");
}