/// Implementation of multiplier, modexp presented in paper:
///   Windowed quantum arithmetic
///   Craig Gidney, 2019.
///   https://arxiv.org/abs/1905.07682
/// All numbers are integer, Little Endian.

import QuantumArithmetic.WindowedArithmeticUtils.Util.Max;
import QuantumArithmetic.WindowedArithmeticUtils.Util.FloorLg2;
import QuantumArithmetic.WindowedArithmeticUtils.Fixes.LittleEndian;
import QuantumArithmetic.WindowedArithmeticUtils.Util.ForceMeasureResetBigInt;
import QuantumArithmetic.WindowedArithmeticUtils.Util.BitLength;
import QuantumArithmetic.WindowedArithmeticUtils.Xor.XorEqualConst;
import QuantumArithmetic.WindowedArithmeticUtils.MulAdd_Window.PlusEqualConstTimesLEWindowed;

operation Multiply (nx : Int, ny : Int, result_t : BigInt, 
                    classical_factor_x : BigInt, quantum_factor_y: BigInt) : BigInt {
    let nt = Max(nx+ny, BitLength(result_t)) + 1;
    let w = Max(1, FloorLg2(ny)-2);
    use Quantum_factor_y = Qubit[ny];
    use Result_t = Qubit[nt];
    let vy = LittleEndian(Quantum_factor_y);
    let vt = LittleEndian(Result_t);
    XorEqualConst(vy, quantum_factor_y);
    XorEqualConst(vt, result_t);
    PlusEqualConstTimesLEWindowed(vt, classical_factor_x, vy, w);
    let a = ForceMeasureResetBigInt(vy, quantum_factor_y);
    let result = ForceMeasureResetBigInt(vt, result_t + classical_factor_x*quantum_factor_y);
    return result;
}

export Multiply;