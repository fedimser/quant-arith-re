import TestUtils.BinaryOp;
import TestUtils.BinaryOpInPlace;
import TestUtils.BinaryOpInPlaceExtraOut;
import QuantumArithmetic.DM2004;
import QuantumArithmetic.CT2002;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    // let x = 16;
    // let y = 4;
    // let ans = BinaryOp(8, x, y, CT2002.Add);
    // Message($"ans={ans}");

    // let x = 9;
    // let y = 5;
    // let n = 4;
    // let ans = BinaryOpInPlaceExtraOut(n, x, y, DM2004.Add);
    // Message($"ans={ans}");

    let x = 9;
    let y = 9;
    let n = 4;
    let ans = BinaryOpInPlace(n, x, y, DM2004.Add_Mod2);
    Message($"ans={ans}");
}

