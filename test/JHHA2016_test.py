import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [1, 2, 5, 8, 16, 31, 32, 64, 100])
def test_Multiply(n: int):
    op = "QuantumArithmetic.JHHA2016.Multiply"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.TestMultiply({n},{n},{a}L,{b}L,{op})")
        assert ans == a*b


@pytest.mark.parametrize("n", [1, 2, 3, 5, 8, 16, 32, 63])
def test_Subtract(n: int):
    op = "QuantumArithmetic.JHHA2016.Add_Mod2N"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == (x+y) % (2**n)
