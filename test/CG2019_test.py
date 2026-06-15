import random

import pytest

from superposition_test_utils import check_superposition_binary
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64, 80, 100])
def test_MultiplySchoolbook(n: int):
    op = "QuantumArithmetic.CG2019.MultiplySchoolbook"
    tester = ArithmeticOpTester(op, [n, n, 2 * n])
    x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
    assert tester.run([x, y, 0]) == [x, y, x * y]


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64, 80, 100])
def test_MultiplyKaratsuba(n: int):
    op = "QuantumArithmetic.CG2019.MultiplyKaratsuba"
    tester = ArithmeticOpTester(op, [n, n, 2 * n])
    x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
    assert tester.run([x, y, 0]) == [x, y, x * y]


def test_superposition():
    n = 8
    op = "QuantumArithmetic.CG2019.MultiplyKaratsuba"
    classical_op = lambda x, y: x * y
    check_superposition_binary([n, n, 2 * n], op, classical_op)
