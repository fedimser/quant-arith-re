import TestUtils.*;
import QuantumArithmetic.Utils;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 2;
    let a = 2L;
    let b = 3L;
    let ans = TestMultiply(n,n, a, b, QuantumArithmetic.OFOSG2023.MultiplyWallaceTree);
    
    Message($"ans={ans}");
}