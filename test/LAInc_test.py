import math
import random

import pytest

from test_utils import ArithmeticOpTester


def _ctz(x: int) -> int:
    """Count trailing zeroes."""
    return (x & -x).bit_length() - 1


def _cto(x: int) -> int:
    """Count trailing ones."""
    return _ctz(x + 1)


@pytest.mark.parametrize("x_size", [1, 2, 3, 4, 5, 6])
def test_CountTrailingOnes_exhaustive(x_size: int):
    op = "QuantumArithmetic.LAInc.CountTrailingOnes"
    ans_size = math.floor(math.log2(x_size)) + 1
    tester = ArithmeticOpTester(op, [x_size, ans_size])
    for x in range(2**x_size):
        result = tester.run([x, 0])
        assert result == [x, _cto(x)]


@pytest.mark.parametrize("x_size", [10, 20, 30])
def test_CountTrailingOnes(x_size: int):
    op = "QuantumArithmetic.LAInc.CountTrailingOnes"
    ans_size = math.floor(math.log2(x_size)) + 1
    tester = ArithmeticOpTester(op, [x_size, ans_size])
    for ones_count in range(0, x_size + 1):
        x = 2**ones_count - 1
        r = x_size - (ones_count + 1)
        if r > 0:
            x += (random.randint(0, 2**r - 1)) << (ones_count + 1)
        result = tester.run([x, 0])
        assert result == [x, ones_count]


@pytest.mark.parametrize("target_size", [1, 2, 3, 4, 5, 6, 7, 8, 10, 20, 30])
def test_FlipFirst(target_size: int):
    op = "QuantumArithmetic.LAInc.FlipFirst"
    ctr_size = math.floor(math.log2(target_size)) + 1
    tester = ArithmeticOpTester(op, [target_size, ctr_size])
    for flip_count in range(target_size + 1):
        assert flip_count < 2**ctr_size
        target_init = random.randint(0, 2**target_size - 1)
        result = tester.run([target_init, flip_count])
        assert result == [target_init ^ ((1 << flip_count) - 1), flip_count]
