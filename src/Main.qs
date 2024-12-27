import TestUtils.*;
import QuantumArithmetic.Utils;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 4;
    let a = 10L;
    let b = 10L;
//    let ans = TestMultiply(n,n, a, b, QuantumArithmetic.OFOSG2023.MultiplyWallaceTree);
    let ans : Int = BinaryOpInPlaceRadix(15, 4, 5, 3, QuantumArithmetic.WBC2023.Add);

    
    Message($"ans={ans}");
}