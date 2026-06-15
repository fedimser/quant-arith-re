import random

import pytest

from superposition_test_utils import (
    check_superposition_unary_inplace,
    check_superposition_binary_inplace,
)
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [8, 16])
def test_RotateRight(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.Utils.RotateRight", [n])
    for _ in range(5):
        x = random.randint(0, 2**n - 1)
        assert tester.run([x])[0] == (x >> 1) + ((x % 2) << (n - 1))


@pytest.mark.parametrize("n", [8, 16])
def test_RotateLeft(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.Utils.RotateLeft", [n])
    for _ in range(5):
        x = random.randint(0, 2**n - 1)
        assert tester.run([x])[0] == (x % (2 ** (n - 1)) << 1) + (x >> (n - 1))


@pytest.mark.parametrize("n", [8, 16])
def test_Subtract(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.Utils.Subtract", [n, n])
    for _ in range(5):
        x = random.randint(0, 2**n - 1)
        y = random.randint(0, 2**n - 1)
        assert tester.run([x, y]) == [x, (y - x) % (2**n)]


def test_superposition_RotateRight():
    n = 8
    op = "QuantumArithmetic.Utils.RotateRight"
    classical_op = lambda x: (x >> 1) + ((x % 2) << (n - 1))
    check_superposition_unary_inplace(n, op, classical_op)


def test_superposition_RotateLeft():
    n = 8
    op = "QuantumArithmetic.Utils.RotateLeft"
    classical_op = lambda x: (x % (2 ** (n - 1)) << 1) + (x >> (n - 1))
    check_superposition_unary_inplace(n, op, classical_op)


def test_superposition_Subtract():
    n = 8
    op = "QuantumArithmetic.Utils.Subtract"
    classical_op = lambda x, y: (y - x) % (2**n)
    check_superposition_binary_inplace(n, op, classical_op)
