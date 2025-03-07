import pytest
from qsharp import init, eval
import math


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n1,n2", [(2, 3), (3, 13), (4, 41)])
def test_Factorial(n1: int, n2: int):
    op = "QuantumArithmetic.TableFunctions.Factorial"
    for i in range(2**n1):
        ans = eval(f"TestUtils.BinaryOpArb({n1},{n2},{i}L,0L,{op})")
        assert ans == (i, math.factorial(i))
