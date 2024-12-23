import Std.Convert.IntAsBigInt;
import Std.Diagnostics.Fact;


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
