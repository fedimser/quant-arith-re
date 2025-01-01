import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 62])
def test_AddMod2NMinus1OutOfPlace(n: int):
    MOD = 2**n-1
    op = "QuantumArithmetic.AdditionOrig.AddMod2NMinus1OutOfPlace"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOp({n},{a}L,{b}L,{op})")
        assert ans % MOD == (a+b) % MOD


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 62])
def test_AddMod2NMinus1InPlace(n: int):
    MOD = 2**n-1
    op = "QuantumArithmetic.AdditionOrig.AddMod2NMinus1InPlace"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{a}L,{b}L,{op})")
        assert ans % MOD == (a+b) % MOD


@pytest.mark.parametrize("n",  [1, 2, 3, 4, 5, 8, 15, 16, 32, 64])
def test_AddConstant(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(-2*N, 2*N)
        b = random.randint(0, N-1)
        op = f"QuantumArithmetic.AdditionOrig.AddConstant({a}L,_)"
        ans = eval(f"TestUtils.UnaryOpInPlaceCtl({n},{b}L,{op})")
        assert ans == (a+b) % N
