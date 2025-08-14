import pytest
from qsharp import init, eval
import random

from superposition_test_utils import (
    check_superposition_unary_inplace,
    check_superposition_binary_inplace,
)


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [8, 16])
def test_RotateRight(n: int):
    op = "QuantumArithmetic.Utils.RotateRight"
    for _ in range(5):
        x = random.randint(0, 2**n - 1)
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        expected = (x >> 1) + ((x % 2) << (n - 1))
        assert ans == expected


@pytest.mark.parametrize("n", [8, 16])
def test_RotateLeft(n: int):
    op = "QuantumArithmetic.Utils.RotateLeft"
    for _ in range(5):
        x = random.randint(0, 2**n - 1)
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        expected = (x % (2 ** (n - 1)) << 1) + (x >> (n - 1))
        assert ans == expected


@pytest.mark.parametrize("n", [8, 16])
def test_Subtract(n: int):
    op = "QuantumArithmetic.Utils.Subtract"
    for _ in range(5):
        x = random.randint(0, 2**n - 1)
        y = random.randint(0, 2**n - 1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == (y - x) % (2**n)


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
