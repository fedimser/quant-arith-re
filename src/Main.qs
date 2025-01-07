import QuantumArithmetic.MCT2017.Multiply;
import TestUtils.*;
import QuantumArithmetic.Utils;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 4;
    let a = 10L;
    let b = 5L;
    let t = 1L;
    let ans = QuantumArithmetic.CG20192.MultiplyWindow(n,n,t,a,b,2);
    Message($"ans={ans}");
}