import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("op", ["QuantumArithmetic.LYTZW2013.Increment_v1"])
@pytest.mark.parametrize("n", [1, 2, 3, 4, 5])
def test_Increment_Exhaustive(op: str, n: int):
    N = 2**n
    for x in range(N):
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        assert ans == (x+1) % N
