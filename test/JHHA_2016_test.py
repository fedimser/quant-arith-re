import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [5, 8, 32, 62, 63])
def test_RotateRight(n: int):
    op = "QuantumArithmetic.JHHA2016.RotateRight"
    for _ in range(5):
        x = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x},{op})")
        expected = (x >> 1) + ((x % 2) << (n-1))
        assert ans == expected


@pytest.mark.parametrize("n", [1, 2, 5, 8, 16, 31, 32, 64, 100])
def test_Multiply(n: int):
    op = "QuantumArithmetic.JHHA2016.Multiply"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.TestMultiply({n},{a}L,{b}L,{op})")
        expected = a*b
        assert ans == expected
