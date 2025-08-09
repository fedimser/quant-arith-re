/// Implementation of multiplier, modexp presented in paper:
///   Windowed quantum arithmetic
///   Craig Gidney, 2019.
///   https://arxiv.org/abs/1905.07682
///
/// This code and utils in WindowedArithmeticUtils are adapted from
/// https://github.com/Strilanc/windowed-quantum-arithmetic
///
/// Acknowledgment:
///   We thank Craig Gidney for the work presented in the paper and
///   the GitHub repo that inspired and guided this implementation. 


import QuantumArithmetic.WindowedArithmeticUtils.Util.Max;
import QuantumArithmetic.WindowedArithmeticUtils.Util.FloorLg2;
import QuantumArithmetic.WindowedArithmeticUtils.Fixes.LittleEndian;
import QuantumArithmetic.WindowedArithmeticUtils.Util.ForceMeasureResetBigInt;
import QuantumArithmetic.WindowedArithmeticUtils.Util.BitLength;
import QuantumArithmetic.WindowedArithmeticUtils.Xor.XorEqualConst;
import QuantumArithmetic.WindowedArithmeticUtils.MulAdd_Window.PlusEqualConstTimesLEWindowed;
import QuantumArithmetic.Utils;
import Std.Arrays;
import Std.Convert;
import Std.Math;
import Std.TableLookup.*;
import Std.Arithmetic.RippleCarryCGIncByLE;
import QuantumArithmetic.LYY2021.ModAdd;

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


operation MultiplyWindow (nx : Int, ny : Int, result_t : BigInt, 
                    classical_factor_x : BigInt, quantum_factor_y: BigInt,
                    w: Int) : BigInt {
    let nt = Max(nx+ny, BitLength(result_t)) + 1;
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

internal function Skip2Data(
    generator: BigInt, period: BigInt, num_exponents: Int, num_bits: Int
) : Bool[][] {
    mutable total = 1L;
    let num_entries = 1 <<< num_exponents;
    mutable table = [[false, size = num_bits], size = num_entries];
    
    for k2 in 0..num_entries-1 {
        // Convert total to bits (little-endian)
        set table w/= k2 <- Convert.BigIntAsBoolArray(total, num_bits);
        set total *= generator;
        set total %= period;
    }
    
    return table;
}

/// Computes ans=(base^exponent)%modulus.
/// ans must be prepared in zero state.
/// base must be coprime with modulus.
/// Doesn't change exponent.
/// Fig. 7 in the paper
operation ModExpWindow(exponent : Qubit[], ans : Qubit[], base : BigInt, modulus : BigInt,
                       expWindowLen : Int, mulWindowLen : Int
) : Unit is Adj + Ctl {
    let n1 = Length(exponent);
    let n2 = Length(ans);

    let expWindows = Arrays.Chunks(expWindowLen, exponent);

    // skip the first two expWindows with a direct lookup
    // based on Gidney 2025 (https://arxiv.org/abs/2505.15917)
    let skipNum = 
        if (expWindowLen * 2 < n1) {
            expWindowLen * 2
        } else {
            n1
        };
    let data = Skip2Data(base, modulus, skipNum, n2);
    use output = Qubit[n2];
    within {
        Select(data, expWindows[0] + expWindows[1], output);
    } apply {
        Utils.ParallelCNOT(output, ans);
    }

    for i in 2..Length(expWindows)-1 {
        let adjustedBase = Math.ExpModL(base, 1L <<< (i * expWindowLen), modulus);
        if (i % 2 == 1) {
            AddExpModWindowed(adjustedBase, modulus, 1, mulWindowLen, expWindows[i], output, ans);
            AddExpModWindowed(Math.InverseModL(adjustedBase, modulus), modulus, -1, mulWindowLen, expWindows[i], ans, output);
        } else{
            AddExpModWindowed(adjustedBase, modulus, 1, mulWindowLen, expWindows[i], ans, output);
            AddExpModWindowed(Math.InverseModL(adjustedBase, modulus), modulus, -1, mulWindowLen, expWindows[i], output, ans);
        }
    }
    if (Length(expWindows) % 2 == 1) {
        // Handle the case where there are more than 2 exponent windows
        Utils.ParallelSWAP(ans, output);
    }
}

internal function ModExpData(factor : BigInt, expLength : Int, mulLength : Int, base : BigInt, mod : BigInt, sign : Int, numBits : Int) : Bool[][] {
    mutable data = [[false, size = numBits], size = 2^(expLength + mulLength)];
    for b in 0..2^mulLength - 1 {
        for a in 0..2^expLength - 1 {
            let idx = b * 2^expLength + a;
            let value = Math.ModulusL(factor * Convert.IntAsBigInt(b) * Convert.IntAsBigInt(sign) * (base^a), mod);
            set data w/= idx <- Convert.BigIntAsBoolArray(value, numBits);
        }
    }

    data
}

/// # Summary
/// Computes zs += ys * (base ^ xs) % mod (for small registers xs and ys)
///
/// # Reference
/// [arXiv:1905.07682, Fig. 5](https://arxiv.org/abs/1905.07682)
///
/// # Remark
/// Unlike in the reference, this implementation uses regular addition
/// instead of modular addition because the target register is encoded
/// using the coset representation.
internal operation AddExpModWindowed(
    base : BigInt,
    mod : BigInt,
    sign : Int,
    mulWindowLen : Int,
    xs : Qubit[],
    ys : Qubit[],
    zs : Qubit[]
) : Unit is Adj + Ctl {
    // split factor into parts
    let factorWindows = Arrays.Chunks(mulWindowLen, ys);

    for i in 0..Length(factorWindows)-1 {
        // compute data for table lookup
        let factorValue = Math.ExpModL(2L, Convert.IntAsBigInt(i * mulWindowLen), mod);
        let data = ModExpData(factorValue, Length(xs), Length(factorWindows[i]), base, mod, sign, Length(zs));

        use output = Qubit[Length(data[0])];

        within {
            Select(data, xs + factorWindows[i], output);
        } apply {
            ModAdd(output, zs, mod);
        }
    }
}

export Multiply, MultiplyWindow, ModExpWindow;