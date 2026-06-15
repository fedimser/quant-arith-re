import pytest
import random

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [2, 3, 5, 8, 16, 32, 63])
def test_Subtract(n: int):
    op = "QuantumArithmetic.TR2009.Subtract"
    tester = ArithmeticOpTester(op, [n, n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y, 0]) == [x, y, (x - y) % (2**n)]
