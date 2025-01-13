import QuantumArithmetic.Xin2018.CompareLess;
import TestUtils.*;
import QuantumArithmetic.Utils;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 1;
    let a = 1L;
    let b = 1L;
    let ans = TestCompare(n, a, b, CompareLess);
    Message($"ans={ans}");
}