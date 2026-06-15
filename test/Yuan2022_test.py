import random

import pytest
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [3, 4, 7, 8, 9, 11, 12])
def test_subtract_equal(n: int):
    op = "QuantumArithmetic.Yuan2022.Subtract_EqualBit"
    tester = ArithmeticOpTester(op, [n, n])
    for _ in range(10):
        x = random.randint(0, 2**n - 1)
        y = random.randint(0, 2**n - 1 if x > 2**n - 1 else x)
        ans = tester.run([y, x])
        assert ans == [y, (x - y) % (2**n)]


@pytest.mark.parametrize("n", [3, 4, 7, 8, 9, 11, 12])
def test_subtract_unequal(n: int):
    op = "QuantumArithmetic.Yuan2022.Subtract_NotEqualBit"
    m = n - 1
    tester = ArithmeticOpTester(op, [m, n])
    for _ in range(10):
        y = random.randint(0, 2**n - 1)
        x = random.randint(0, 2**m - 1 if y > 2**m - 1 else y)
        ans = tester.run([x, y])
        assert ans == [x, (y - x) % (2**n)]


@pytest.mark.parametrize("n", [4, 6, 8, 16, 24, 32, 63])
def test_division(n: int):
    op = "QuantumArithmetic.Yuan2022.Divide"
    m = n // 2
    tester = ArithmeticOpTester(op, [n, m, n - m + 1])
    for _ in range(10):
        x = random.randint(2**m - 1, 2**n - 1)
        y = random.randint(2 ** (m - 1), 2**m - 1)
        ans = tester.run([x, y, 0])
        assert ans == [x % y, y, x // y]
