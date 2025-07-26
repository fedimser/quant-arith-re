import pytest
from qsharp import init, eval
import random

from superposition_test_utils import check_superposition_binary


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [2, 3, 4, 5, 8, 9, 16, 17, 32, 33])
def test_Add(n: int):
    op = "QuantumArithmetic.SC2023.Add"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpExtraOut({n},{x}L,{y}L,{op})")
        assert ans == (x+y) 


@pytest.mark.parametrize("n", [3, 32, 63])
def test_Add_Mod2N(n: int):
    op = "QuantumArithmetic.SC2023.Add_Mod2N"
    for _ in range(5):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op})")
        assert ans == (x+y)%(2**n) 


def test_superposition():
    n = 8
    op = "QuantumArithmetic.SC2023.Add_Mod2N"
    classical_op = lambda x, y: (x + y) % (2**n)
    check_superposition_binary([n,n,n], op, classical_op)
