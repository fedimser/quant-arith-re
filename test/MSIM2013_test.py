import math
import random

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [2, 3])
def test_GreatestCommonDivisor_exhaustive(n: int):
    op = "QuantumArithmetic.MSIM2013.GreatestCommonDivisor"
    tester = ArithmeticOpTester(op, [n, n, n])
    for x in range(2**n):
        for y in range(2**n):
            assert tester.run([x, y, 0])[2] == math.gcd(x, y)


@pytest.mark.parametrize("n", [4, 5, 6, 7, 8, 9, 10, 16, 32])
def test_GreatestCommonDivisor_random(n: int):
    op = "QuantumArithmetic.MSIM2013.GreatestCommonDivisor"
    tester = ArithmeticOpTester(op, [n, n, n])
    for _ in range(5 if n <= 8 else 1):
        g = random.randint(1, 2 ** (n // 2))
        x = g * random.randint(0, (2**n) // g - 1)
        y = g * random.randint(0, (2**n) // g - 1)
        assert tester.run([x, y, 0])[2] == math.gcd(x, y)
