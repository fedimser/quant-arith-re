import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [2, 3]) # needs to debug 4 and 5
def test_Add(n: int):
    op = "QuantumArithmetic.SC2023.Add"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpExtraOut({n},{x},{y},{op})")
        assert ans == (x+y) % (2**n)
