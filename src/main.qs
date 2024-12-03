import QuantumArithmetic.Test.*;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let x = 16;
    let y = 3;
    let ans = PerformArithmeticOperation(8, x, y, QuantumArithmetic.Add_DKRS);
    Message($"ans={ans}");
}