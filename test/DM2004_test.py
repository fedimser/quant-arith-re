import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [2, 8, 16, 32])
def test_Add(n: int):
    op = "QuantumArithmetic.DM2004.Add"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlaceExtraOut({n},{x}L,{y}L,{op})")
        assert ans == (x+y)

@pytest.mark.parametrize("n", [2, 8, 16, 32])
def test_Add_Mod2(n: int):
    op = "QuantumArithmetic.DM2004.Add_Mod2"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == (x+y) % (2**n)