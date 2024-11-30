import QuantumArithmetic.Test.*;

// For development only.

operation Main() : Unit {
    let x1 : Int = PerformArithmeticOperationInPlace(5, 5, 3, 10, QuantumArithmetic.IncByLE);
    let x2 : Int = PerformArithmeticOperationInPlace(8, 8, 60, 7, QuantumArithmetic.IncByLE);
    Message($"x1 = {x1}");
    Message($"x2 = {x2}");
}