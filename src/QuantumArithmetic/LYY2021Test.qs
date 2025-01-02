import Std.Diagnostics.Fact;
import TestUtils.MeasureBigInt;

operation TestTableLookup(n: Int, m: Int, table: BigInt[]) : BigInt[] {
   use A = Qubit[m];
   use B = Qubit[n];
   mutable ans: BigInt[] = [];
   for i in 0..(1<<<m)-1 {
        ApplyPauliFromInt(PauliX, true, i, A);
        QuantumArithmetic.LYY2021.TableLookup(A, B, table);
        set ans += [MeasureBigInt(B)];
        ResetAll(A);  
   } 
   return ans;
}