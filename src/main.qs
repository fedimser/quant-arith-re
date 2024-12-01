import QuantumArithmetic.Test.*;



operation Main() : Unit {
    let x = 8;
    let y = 1;
    let (quot, rem) = Test_Divide_TMVH_Restoring(4, x, y);
    Message($"q={quot}, r={rem}");
}