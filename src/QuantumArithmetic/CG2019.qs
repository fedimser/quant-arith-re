/// Implementation of multiplier presented in paper:
///   Asymptotically Efficient Quantum Karatsuba Multiplication
///   Craig Gidney, 2019.
///   https://arxiv.org/abs/1904.07356
/// All numbers are integer, Little Endian.

import Std.Diagnostics.Fact;
import Std.Math.*;
import QuantumArithmetic.Utils.Rearrange2D;

operation PlusEqual(lvalue : Qubit[], offset : Qubit[]) : Unit is Adj + Ctl {
    use carryIn = Qubit();
    let trimmedOffset = offset[0..Min([Length(lvalue), Length(offset)])-1];
    if (Length(trimmedOffset) > 0) {
        use pad = Qubit[Max([0, Length(lvalue) - Length(trimmedOffset)])];
        let paddedOffset = trimmedOffset + pad;
        QuantumArithmetic.CDKM2004.AddUnoptimized(paddedOffset, lvalue);
    }
}

operation LetAnd(lvalue : Qubit, a : Qubit, b : Qubit) : Unit is Adj + Ctl {
    CCNOT(a, b, lvalue);

}

operation DelAnd(lvalue : Qubit, a : Qubit, b : Qubit) : Unit is Adj + Ctl {
    Adjoint LetAnd(lvalue, a, b);

}

operation PlusEqualProductUsingSchoolbook(
    lvalue : Qubit[],
    factor1 : Qubit[],
    factor2 : Qubit[]
) : Unit is Adj + Ctl {
    let n1 = Length(factor1);
    let n2 = Length(factor2);
    use w = Qubit[n2];
    for k in 0..n1-1 {
        let v = w;

        for i in 0..n2-1 {
            LetAnd(v[i], factor2[i], factor1[k]);
        }

        let tail = lvalue[k..Length(lvalue)-1];
        PlusEqual(tail, v);

        for i in 0..n2-1 {
            DelAnd(v[i], factor2[i], factor1[k]);
        }
    }
}


function SplitPadBuffer(buf : Qubit[], pad : Qubit[], base_piece_size : Int, desired_piece_size : Int, piece_count : Int) : Qubit[][] {
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

function FloorBigLg2(n : BigInt) : Int {
    return QuantumArithmetic.Utils.FloorLog2(n);
}

function CeilBigLg2(n : BigInt) : Int {
    if (n <= 1L) {
        return 0;
    }
    return FloorBigLg2(n - 1L) + 1;
}

function CeilLg2(n : Int) : Int {
    return CeilBigLg2(Std.Convert.IntAsBigInt(n));
}

function CeilMultiple(numerator : Int, multiple : Int) : Int {
    return ((numerator + multiple - 1) / multiple) * multiple;
}

function CeilPowerOf2(n : Int) : Int {
    return 1 <<< CeilLg2(n);
}


operation _PlusEqualProductUsingKaratsubaOnPieces(
    output_pieces : Qubit[][],
    input_pieces_1 : Qubit[][],
    input_pieces_2 : Qubit[][]
) : Unit is Adj {

    let n = Length(input_pieces_1);
    Fact(Length(input_pieces_2) == n, "");
    Fact(Length(output_pieces) == 2 * n, "");
    if (n <= 1) {
        if (n == 1) {

            PlusEqualProductUsingSchoolbook(
                output_pieces[0],
                input_pieces_1[0],
                input_pieces_2[0]
            );

        }
    } else {
        let h = n >>> 1;

        // Input 1 is logically split into two halves (a, b) such that a + 2**(wh) * b equals the input.
        // Input 2 is logically split into two halves (x, y) such that x + 2**(wh) * y equals the input.

        //-----------------------------------
        // Perform
        //     out += a*x * (1-2**(wh))
        //     out -= b*y * 2**(wh) * (1-2**(wh))
        //-----------------------------------
        // Temporarily inverse-multiply the output by 1-2**(wh), so that the following two multiplied additions are scaled by 1-2**(wh).
        if (true) {
            within {
                for i in h..4 * h - 1 {
                    PlusEqual(output_pieces[i], output_pieces[i - h]);
                }
            } apply {
                // Recursive multiply-add for a*x.
                _PlusEqualProductUsingKaratsubaOnPieces(
                    output_pieces[0..2 * h-1],
                    input_pieces_1[0..h-1],
                    input_pieces_2[0..h-1]
                );
                // Recursive multiply-subtract for b*y.
                Adjoint _PlusEqualProductUsingKaratsubaOnPieces(
                    output_pieces[h..3 * h-1],
                    input_pieces_1[h..2 * h-1],
                    input_pieces_2[h..2 * h-1]
                );
            }
        }

        //PrintBuffers("L1", output_pieces);

        //-------------------------------
        // Perform
        //     out += (a+b)*(x+y) * 2**(wh)
        //-------------------------------
        // Temporarily store a+b over a and x+y over x.
        if (true) {
            within {
                for i in 0..h-1 {
                    PlusEqual(input_pieces_1[i], input_pieces_1[i + h]);
                    PlusEqual(input_pieces_2[i], input_pieces_2[i + h]);
                }
            } apply {
                // Recursive multiply-add for (a+b)*(x+y).
                _PlusEqualProductUsingKaratsubaOnPieces(
                    output_pieces[h..3 * h-1],
                    input_pieces_1[0..h-1],
                    input_pieces_2[0..h-1]
                );
            }
        }
    }
}

operation _PlusEqualProductUsingKaratsuba_Helper(
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



    //PrintBuffers("before Karatsuba", work_bufs);

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
operation Multiply(A : Qubit[], B : Qubit[], C : Qubit[]) : Unit {
    let min_piece_size = 8; // 32 in the original paper.
    let piece_size = Max([min_piece_size, 2 * CeilLg2(Max([Length(A), Length(B)]))]);
    _PlusEqualProductUsingKaratsuba_Helper(C, A, B, piece_size);
}

export Multiply;
