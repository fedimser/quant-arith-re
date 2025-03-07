/// Implementation of multiplier presented in paper:
///   Asymptotically Efficient Quantum Karatsuba Multiplication
///   Craig Gidney, 2019.
///   https://arxiv.org/abs/1904.07356
/// All numbers are integer, Little Endian.

import Std.Diagnostics.Fact;
import Std.Math.*;
import QuantumArithmetic.Utils.*;

operation PlusEqual(lvalue : Qubit[], offset : Qubit[]) : Unit is Adj + Ctl {
    let trimmedOffset = offset[0..Min([Length(lvalue), Length(offset)])-1];
    if (Length(trimmedOffset) > 0) {
        use pad = Qubit[Max([0, Length(lvalue) - Length(trimmedOffset)])];
        let paddedOffset = trimmedOffset + pad;
        QuantumArithmetic.CDKM2004.AddUnoptimized(paddedOffset, lvalue);
    }
}

/// Computes C+=A*B.
operation MultiplySchoolbook(
    A : Qubit[],
    B : Qubit[],
    C : Qubit[]
) : Unit is Adj + Ctl {
    let n1 = Length(A);
    let n2 = Length(B);
    use w = Qubit[n2];
    for k in 0..n1-1 {
        for i in 0..n2-1 {
            CCNOT(B[i], A[k], w[i]);
        }
        PlusEqual(C[k..Length(C)-1], w);
        for i in 0..n2-1 {
            CCNOT(B[i], A[k], w[i]);
        }
    }
}

function SplitPadBuffer(
    buf : Qubit[],
    pad : Qubit[],
    base_piece_size : Int,
    desired_piece_size : Int,
    piece_count : Int
) : Qubit[][] {
    mutable result : Qubit[][] = [];
    mutable k_pad = 0;
    for i in 0..piece_count-1 {
        let k_buf = i * base_piece_size;
        mutable res_i = [];
        if (k_buf < Length(buf)) {
            set res_i = buf[k_buf..Min([k_buf + base_piece_size, Length(buf)])-1];
        }
        let missing = desired_piece_size - Length(res_i);
        set result += [res_i + pad[k_pad..k_pad + missing-1]];
        set k_pad = k_pad + missing;
    }
    return result;
}

function MergeBufferRanges(work_registers : Qubit[][], start : Int, len : Int) : Qubit[] {
    mutable result : Qubit[] = [];
    for i in 0..Length(work_registers)-1 {
        for j in 0..len-1 {
            set result += [work_registers[i][start + j]];
        }
    }
    return result;
}

function CeilLg2(n : Int) : Int {
    if (n <= 1) {
        return 0;
    }
    return FloorLog2(Std.Convert.IntAsBigInt(n) - 1L) + 1;
}

function CeilMultiple(numerator : Int, multiple : Int) : Int {
    return ((numerator + multiple - 1) / multiple) * multiple;
}

function CeilPowerOf2(n : Int) : Int {
    return 1 <<< CeilLg2(n);
}

operation _PlusEqualProductUsingKaratsubaOnPieces(
    out : Qubit[][],
    in1 : Qubit[][],
    in2 : Qubit[][]
) : Unit is Adj {
    let n = Length(in1);
    Fact(Length(in2) == n, "Size msimatch.");
    Fact(Length(out) == 2 * n, "Size msimatch.");
    if (n <= 1) {
        if (n == 1) {
            MultiplySchoolbook(in1[0], in2[0], out[0]);
        }
    } else {
        let h = n >>> 1;
        within {
            for i in h..4 * h - 1 {
                PlusEqual(out[i], out[i - h]);
            }
        } apply {
            _PlusEqualProductUsingKaratsubaOnPieces(out[0..2 * h-1], in1[0..h-1], in2[0..h-1]);
            Adjoint _PlusEqualProductUsingKaratsubaOnPieces(out[h..3 * h-1], in1[h..2 * h-1], in2[h..2 * h-1]);
        }
        within {
            for i in 0..h-1 {
                PlusEqual(in1[i], in1[i + h]);
                PlusEqual(in2[i], in2[i + h]);
            }
        } apply {
            _PlusEqualProductUsingKaratsubaOnPieces(out[h..3 * h-1], in1[0..h-1], in2[0..h-1]);
        }
    }
}

operation MultiplyKaratsubaHelper(
    lvalue : Qubit[],
    factor1 : Qubit[],
    factor2 : Qubit[],
    piece_size : Int
) : Unit {
    let piece_count = CeilPowerOf2(CeilMultiple(Max([Length(factor1), Length(factor2)]), piece_size) / piece_size);
    let in_buf_piece_size = piece_size + CeilLg2(piece_count);
    let work_buf_piece_size = CeilMultiple(piece_size * 2 + CeilLg2(piece_count) * 4, piece_size);

    // Create input pieces with enough padding to add them together.
    use in_bufs_backing1 = Qubit[in_buf_piece_size * piece_count - Length(factor1)];
    use in_bufs_backing2 = Qubit[in_buf_piece_size * piece_count - Length(factor2)];
    let in_bufs1 : Qubit[][] = SplitPadBuffer(factor1, in_bufs_backing1, piece_size, in_buf_piece_size, piece_count);
    let in_bufs2 : Qubit[][] = SplitPadBuffer(factor2, in_bufs_backing2, piece_size, in_buf_piece_size, piece_count);

    // Create workspace pieces with enough padding to hold multiplied summed input pieces, and to add them together.
    use work_bufs_backing = Qubit[work_buf_piece_size * piece_count * 2];
    let work_bufs : Qubit[][] = Rearrange2D(work_bufs_backing, 2 * piece_count, work_buf_piece_size);

    // Add into workspaces, merge into output, then uncompute workspace.
    within {
        _PlusEqualProductUsingKaratsubaOnPieces(work_bufs, in_bufs1, in_bufs2);
    } apply {
        for i in 0..piece_size..work_buf_piece_size-1 {
            let target = lvalue[i..Length(lvalue)-1];
            let shift = MergeBufferRanges(work_bufs, i, piece_size);
            PlusEqual(target, shift);
        }
    }
}

/// Computes C+=A*B.
operation MultiplyKaratsuba(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit {
    let min_piece_size = 8; // 32 in the original paper.
    let piece_size = Max([min_piece_size, 2 * CeilLg2(Max([Length(A), Length(B)]))]);
    MultiplyKaratsubaHelper(C, A, B, piece_size);
}

operation MultiplyKaratsuba32(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit {
    let min_piece_size = 32;
    let piece_size = Max([min_piece_size, 2 * CeilLg2(Max([Length(A), Length(B)]))]);
    MultiplyKaratsubaHelper(C, A, B, piece_size);
}

export MultiplySchoolbook, MultiplyKaratsuba;
