import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n,radix", [(3, 3), (4, 4), (10, 10)])
def test_Add(n: int, radix: int):
    op = "QuantumArithmetic.WBC2023.Add"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op}(_,_,_,{radix}))")
        expected = (x+y) % (2**n)
        assert ans == expected
