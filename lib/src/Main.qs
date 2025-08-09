import QuantumArithmetic.CG20192.ModExpWindow;
import TestUtils.*;
import QuantumArithmetic.Utils;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 6;
    let a = 2L;
    let x = 42L;
    let N = 11L;
    let ans = TestModExp(n, a, x, N, ModExpWindow(_, _, _, _, 2, 2));
    Message($"ans={ans}");
}