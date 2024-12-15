import TestUtils.BinaryOp;
import TestUtils.BinaryOpInPlace;
import TestUtils.BinaryOpInPlaceExtraOut;
import QuantumArithmetic.PG2012Test;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 3;
    let a = 3;
    let b = 3;
    Message($"mul={PG2012Test.TestFMAC(n,a,0,b)}");
    Message($"div={PG2012Test.TestGMFDIV(n,49,7)}");
    Message($"ans1={PG2012Test.TestFMAC_MOD2(n, a, b, 7)}");
    Message($"ans1={PG2012Test.TestFMUL_MOD2(n, a, b, 7)}");
}