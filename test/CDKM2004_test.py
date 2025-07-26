import pytest
from qsharp import init, eval
import random

from superposition_test_utils import check_superposition_binary_inplace


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [1, 2, 3, 5, 8, 16, 32, 63])
@pytest.mark.parametrize(
    "op",
    [
        "QuantumArithmetic.CDKM2004.Add",
        "QuantumArithmetic.CDKM2004.AddUnoptimized",
    ],
)
def test_Add(n: int, op: str):
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        expected = (x + y) % (2**n)
        assert ans == expected


@pytest.mark.parametrize(
    "op",
    [
        "QuantumArithmetic.CDKM2004.Add",
        "QuantumArithmetic.CDKM2004.AddUnoptimized",
    ],
)
def test_superposition(op: str):
    n = 8
    classical_op = lambda x, y: (x + y) % (2**n)
    check_superposition_binary_inplace(n, op, classical_op)
