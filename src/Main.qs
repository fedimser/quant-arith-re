import TestUtils.BinaryOp;
import TestUtils.BinaryOpInPlace;
import QuantumArithmetic.CT2002;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let x = 16;
    let y = 4;
    let ans = BinaryOp(8, x, y, CT2002.Add);
    Message($"ans={ans}");
}