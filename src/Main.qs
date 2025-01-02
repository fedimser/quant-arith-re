import TestUtils.*;
import QuantumArithmetic.Utils;


// For debugging, run with Ctrl+F5,
operation Main() : Unit {
    let n = 8;
    let m = 1;
    let table: BigInt[] = [15L, 68L];
    QuantumArithmetic.LYY2021Test.TestTableLookup(n,m,table);
    
}