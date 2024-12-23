import QuantumArithmetic.NZLS2023.Butterfly;
import TestUtils.MeasureBigInt;
import Std.Convert.IntAsBigInt;
import Std.Diagnostics.Fact;


operation TestButterfly(n1: Int, A_val: BigInt, B_val: BigInt) : (BigInt, BigInt) {
    use A = Qubit[2*n1];
    use B = Qubit[2*n1];
    TestUtils.ApplyBigInt(A_val, A);
    TestUtils.ApplyBigInt(B_val, B);
    QuantumArithmetic.NZLS2023.Butterfly(A, B);   
    return (MeasureBigInt(A), MeasureBigInt(B)); 
}

operation TestFFT(n1: Int, M1: Int, input: BigInt[]) : BigInt[] {
    let D: Int = Length(input);
    let num_width = 2*n1;
    use qubits = Qubit[D*2*n1];
    mutable X: Qubit[][] = [];
    for i in 0..D-1 {
        set X += [qubits[i*num_width..(i+1)*num_width-1]];
    }

    for i in 0..D-1 {
        TestUtils.ApplyBigInt(input[i], X[i]);
    }
    let g_pwr = 2*M1;
    QuantumArithmetic.NZLS2023.FFT(X, g_pwr);
    mutable ans: BigInt[] = [];
    for i in 0..D-1 {
       set ans += [TestUtils.MeasureBigInt(X[i])];
    }
    return ans;
}
