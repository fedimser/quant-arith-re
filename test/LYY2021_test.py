import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


def test_AddConstant():
    n = 16
    for _ in range(10):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        op = f"QuantumArithmetic.LYY2021.AddConstant({x}L,_)"
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{y}L,{op})")
        assert ans == (x+y) % (2**n)


def test_LeftShift():
    n = 16
    for _ in range(10):
        x = random.randint(0, 2**(n-1)-1)
        op = f"QuantumArithmetic.LYY2021.LeftShift"
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        assert ans == x * 2


@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 10, 20, 32])
def test_ModAdd(n: int):
    for _ in range(10):
        N = random.randint(2, 2**n-1)
        x, y = random.randint(0, N-1), random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModAdd(_,_,{N}L)"
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == (x+y) % N


@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 10, 20, 32])
def test_ModDbl(n: int):
    for _ in range(10):
        N = 1+2*random.randint(1, 2**(n-1)-1)
        x = random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModDbl(_,{N}L)"
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        assert ans == (2*x) % N


@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 10, 20])
def test_ModMulFast(n: int):
    for _ in range(5):
        N = 1+2*random.randint(1, 2**(n-1)-1)
        x, y = random.randint(0, N-1), random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModMulFast(_,_,_,{N}L)"
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op})")
        assert ans == (x*y) % N
