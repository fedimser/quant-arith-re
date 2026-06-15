import math
import random

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 6, 7, 8])
def test_SquareRoot_Exhaustive(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.MCT2018.SquareRoot", [n, n])
    for x in range(2**n):
        true_root = math.floor(math.sqrt(x))
        assert tester.run([x, 0]) == [x - true_root**2, true_root]


@pytest.mark.parametrize(
    "n1,n2",
    [
        (2, 1),
        (2, 3),
        (5, 3),
        (5, 10),
        (10, 5),
        (10, 6),
        (10, 11),
        (16, 8),
        (32, 16),
        (32, 32),
        (64, 32),
        (100, 50),
    ],
)
def test_SquareRoot(n1: int, n2: int):
    tester = ArithmeticOpTester("QuantumArithmetic.MCT2018.SquareRoot", [n1, n2])
    for _ in range(5):
        x = random.randint(0, 2**n1 - 1)
        true_root = math.isqrt(x)
        assert tester.run([x, 0]) == [x - true_root**2, true_root]
