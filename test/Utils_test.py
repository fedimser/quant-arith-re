import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [8, 16])
def test_RotateRight(n: int):
    op = "QuantumArithmetic.Utils.RotateRight"
    for _ in range(5):
        x = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        expected = (x >> 1) + ((x % 2) << (n-1))
        assert ans == expected


@pytest.mark.parametrize("n", [8, 16])
def test_RotateLeft(n: int):
    op = "QuantumArithmetic.Utils.RotateLeft"
    for _ in range(5):
        x = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        expected = (x % (2**(n-1)) << 1) + (x >> (n-1))
        assert ans == expected


@pytest.mark.parametrize("n", [8, 16])
def test_Subtract(n: int):
    op = "QuantumArithmetic.Utils.Subtract"
    for _ in range(5):
        x = random.randint(0, 2**n-1)
        y = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == (y-x) % (2**n)
