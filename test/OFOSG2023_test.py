import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n1,n2", [(2, 2), (2, 16), (9, 2)])
def test_MultiplyWallaceTree(n1: int, n2: int):
    op = "QuantumArithmetic.OFOSG2023.MultiplyWallaceTree"
    for _ in range(5):
        a = random.randint(0, 2**n1-1)
        b = random.randint(0, 2**n2-1)
        ans = eval(f"TestUtils.TestMultiply({n1},{n2},{a}L,{b}L,{op})")
        expected = a*b
        assert ans == expected
