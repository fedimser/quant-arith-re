import QuantumArithmetic.Test.*;

// For development only.

operation Main() : Unit {
    let x2 : Int = PerformArithmeticOperationInPlace(8, 8, 5, 60, QuantumArithmetic.Subtract);
    Message($"x2 = {x2}");
}