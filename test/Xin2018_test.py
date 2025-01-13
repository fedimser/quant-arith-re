import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root=".")

@pytest.mark.parametrize("n", [2, 4, 8, 16, 24, 32, 63])
def test_compare(n: int):
    op = "QuantumArithmetic.Xin2018.CompareLess"
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        ans = eval(f"TestUtils.TestCompare({n},{x}L,{y}L,{op})")
        assert ans == (x < y)
