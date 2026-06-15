import random

import pytest
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [2, 4, 8, 16, 24, 32, 63])
def test_division(n: int):
    op = "QuantumArithmetic.AKBF2011.Divide_Restoring"
    tester = ArithmeticOpTester(op, [n, n, n])
    for _ in range(5):
        a, b = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        result = tester.run([a, b, 0])
        assert result == [a % b, b, a // b]
