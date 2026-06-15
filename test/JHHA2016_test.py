import random

import pytest

from superposition_test_utils import check_superposition_binary
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [1, 2, 5, 8, 16, 31, 32, 64, 100])
def test_Multiply(n: int):
    op = "QuantumArithmetic.JHHA2016.Multiply"
    tester = ArithmeticOpTester(op, [n, n, 2 * n])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        assert tester.run([a, b, 0]) == [a, b, a * b]


@pytest.mark.parametrize("n", [1, 2, 3, 5, 8, 16, 32, 63])
def test_Subtract(n: int):
    op = "QuantumArithmetic.JHHA2016.Add_Mod2N"
    tester = ArithmeticOpTester(op, [n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y]) == [x, (x + y) % (2**n)]


def test_superposition():
    op = "QuantumArithmetic.JHHA2016.Multiply"
    check_superposition_binary([8, 8, 16], op, lambda x, y: x * y)
