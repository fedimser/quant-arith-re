import pytest
from qsharp import init, eval
import random

from superposition_test_utils import check_superposition_binary

@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")

@pytest.mark.parametrize("n", [2, 4, 8, 16, 24, 32, 63])
def test_division(n: int):
    op = "QuantumArithmetic.AKBF2011.Divide_Restoring"
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        q, r = eval(f"TestUtils.Test_Divide_Restoring({n},{x},{y},{op})")
        assert r == x % y
        assert q == x // y

def test_superposition():
    n = 8
    op = "QuantumArithmetic.AKBF2011.Divide_Restoring"
    classical_op = lambda x, y: x // y
    check_superposition_binary([n, n, n], op, classical_op)