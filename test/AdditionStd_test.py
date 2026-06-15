import random

import pytest
from superposition_test_utils import (
    check_superposition_binary,
    check_superposition_binary_inplace,
)
from test_utils import ArithmeticOpTester


from test_utils import CONTEXT


@pytest.mark.parametrize("n", [2, 32])
def test_Add_TTK(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.AdditionStd.Add_TTK", [n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y]) == [x, (x + y) % (2**n)]


@pytest.mark.parametrize("n", [2, 32])
def test_Add_TTK(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.AdditionStd.Add_CG", [n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y]) == [x, (x + y) % (2**n)]


@pytest.mark.parametrize("n", [2, 32])
def test_Add_TTK(n: int):
    op = "QuantumArithmetic.AdditionStd.Add_DKRS"
    tester = ArithmeticOpTester(op, [n, n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y, 0]) == [x, y, (x + y) % (2**n)]


@pytest.mark.parametrize("n", [2, 8])
def test_Add_QFT(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.AdditionStd.Add_QFT", [n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        expected = (x + y) % (2**n)
        assert tester.run([x, y]) == [x, expected]


def test_superposition():
    n = 8
    classical_op = lambda x, y: (x + y) % (2**n)

    op = "QuantumArithmetic.AdditionStd.Add_TTK"
    check_superposition_binary_inplace(n, op, classical_op)

    op = "QuantumArithmetic.AdditionStd.Add_CG"
    check_superposition_binary_inplace(n, op, classical_op)

    op = "QuantumArithmetic.AdditionStd.Add_QFT"
    check_superposition_binary_inplace(n, op, classical_op)

    op = "QuantumArithmetic.AdditionStd.Add_DKRS"
    check_superposition_binary([n, n, n], op, classical_op)
