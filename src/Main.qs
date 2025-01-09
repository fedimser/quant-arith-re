import QuantumArithmetic.WBC2023Test.BinaryOpRadix;
import TestUtils.*;
import QuantumArithmetic.Utils;

// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 16;
    let a = 5361L;
    let b = 11176L;
    let radix = 3; 
    // BinaryOpRadix(n : Int, x_val : BigInt, y_val : BigInt, radix : Int, op : (Qubit[], Qubit[], Qubit[], Int) => Unit) : B
    for _ in 0..10{
        let ans = BinaryOpRadix(n, a, b, radix, QuantumArithmetic.WBC2023.Add);
        if ( ans != 16537L){
            Message($"NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO ans={ans}");

        }
    }
}