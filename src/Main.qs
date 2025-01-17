import QuantumArithmetic.Yuan2022.Divide;
import TestUtils.*;
import QuantumArithmetic.Utils;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 6;
    let m = 2;
    let a = 37;
    let b = 1;
    let ans = Test_Divide_Unequal(n, a, m, b, Divide);
    Message($"ans={ans}");
}