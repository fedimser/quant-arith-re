import TestUtils.*;
import QuantumArithmetic.DKRS2004;
import QuantumArithmetic.Utils;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 3;
    let a = 5;
    let b = 7;
    //let ans = BinaryOpInPlace(n, a, b, DKRS2004.Add);
    let ans = BinaryOpInPlaceExtraOut(n, a, b, DKRS2004.AddWithCarry);
    
    Message($"ans={ans}");
}