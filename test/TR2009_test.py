import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [2, 3, 5, 8, 16, 32, 63])
def test_Subtract(n: int):
    op = "QuantumArithmetic.TR2009.Subtract"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op})")
        expected = (x-y) % (2**n)
        assert ans == expected
