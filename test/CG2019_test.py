import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64, 80, 100])
def test_Multiply(n: int):
    op = "QuantumArithmetic.CG2019.Multiply"
    x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
    ans = eval(f"TestUtils.TestMultiply({n},{x}L,{y}L,{op})")
    assert ans == x*y 
