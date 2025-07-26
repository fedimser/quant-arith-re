import pytest
from qsharp import init, eval
import random

from superposition_test_utils import (
    check_superposition_binary,
    check_superposition_binary_inplace,
)


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [2, 8, 16, 32, 63])
def test_addition(n: int):
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        expected = (x + y) % (2**n)

        op = "QuantumArithmetic.AdditionStd.Add_TTK"
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == expected

        op = "QuantumArithmetic.AdditionStd.Add_CG"
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == expected

        op = "QuantumArithmetic.AdditionStd.Add_DKRS"
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op})")
        assert ans == expected


@pytest.mark.parametrize("n", [2, 8])
def test_Add_QFT(n: int):
    op = "QuantumArithmetic.AdditionStd.Add_QFT"
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        expected = (x + y) % (2**n)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == expected


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
