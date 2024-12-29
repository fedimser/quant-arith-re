import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


def test_AddConstant():
    n = 32
    for _ in range(10):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        op = f"QuantumArithmetic.LYY2021.AddConstant({x}L,_)"
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{y}L,{op})")
        assert ans == (x+y) % (2**n)
