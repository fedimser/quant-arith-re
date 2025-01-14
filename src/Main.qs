import QuantumArithmetic.Orts2024.Subtract_NotEqualBit;
import TestUtils.*;
import QuantumArithmetic.Utils;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 3;
    let m = 2;
    let a = 3L;
    let b = 1L;
    let ans = Test_Subtract_NotEqualBit(n, a, m, b, Subtract_NotEqualBit);
    Message($"ans={ans}");
}