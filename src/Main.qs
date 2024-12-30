import TestUtils.*;
import QuantumArithmetic.Utils;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 6;
    let a = 62;
    let b = 43;
    let radix = 3;
//    let ans = TestMultiply(n,n, a, b, QuantumArithmetic.OFOSG2023.MultiplyWallaceTree);
    let ans : Int = BinaryOpInPlaceRadix(n, a, b, radix, QuantumArithmetic.WBC2023_new.Add);

    
    Message($"ans={ans}");
}