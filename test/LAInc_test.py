import math

import pytest

from test_utils import  ArithmeticOpTester


def _ctz(x: int) -> int:
    """Count trailing zeroes."""
    return (x & -x).bit_length() - 1


def _cto(x: int) -> int:
    """Count trailing ones."""
    return _ctz(x + 1)


@pytest.mark.parametrize("x_size", [1, 2, 3, 4, 5, 6, 7, 8])
def test_CountLowestOnes(x_size: int):
    """Tests CountLowestOnes."""
    op = "QuantumArithmetic.LAInc.CountTrailingOnes"
    ans_size = math.floor(math.log2(x_size)) + 1
    tester = ArithmeticOpTester(op, [x_size, ans_size])
    for x in range(2**x_size):
        result = tester.run([x, 0])
        assert result == [x, _cto(x)]
