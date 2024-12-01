import QuantumArithmetic.Test.*;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let x = 16;
    let y = 3;
    let (quot, rem) = Test_Divide_TMVH_NonRestoring(8, x, y);
    Message($"q={quot}, r={rem}");
}