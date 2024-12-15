import TestUtils.BinaryOp;
import TestUtils.BinaryOpInPlace;
import TestUtils.BinaryOpInPlaceExtraOut;
import QuantumArithmetic.PG2012Test;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 3;
    let a = 5;
    let b = 4;
    //Message($"ans1={PG2012Test.TestFMAC_MOD2(n,a,a,7)}");
    Message($"{a}^{b}={PG2012Test.TestEXP_MOD(n,a,b,7)}");
}