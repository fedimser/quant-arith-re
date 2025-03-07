import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [2, 8, 32, 63, 64])
def test_Add_Mod2N(n: int):
    op = "QuantumArithmetic.GKDKH2021.Add_Mod2N"
    for _ in range(5):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op})")
        expected = (x+y) % (2**n)
        assert ans == expected
