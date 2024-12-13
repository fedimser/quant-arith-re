import TestUtils.BinaryOp;
import TestUtils.BinaryOpInPlace;
import TestUtils.BinaryOpInPlaceExtraOut;
import QuantumArithmetic.PG2012Test;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 3;
    let a = 6;
    let b = 4;
    let (q, r) = PG2012Test.TestGMFDIV(n, a, b);
    Message($"q={q} r={r}");
}