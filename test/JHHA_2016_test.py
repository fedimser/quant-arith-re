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
        expected = (x>>1)  + ((x%2) << (n-1))
        assert ans == expected
