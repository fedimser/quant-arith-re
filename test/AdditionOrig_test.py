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


@pytest.mark.parametrize("n",  [1, 2, 3, 4, 5, 8, 16, 32])
def test_OverflowBit(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(0, N-1)
        b = random.randint(0, N-1)
        ci = random.randint(0, 1)  # carry in.
        ci_txt = "true" if ci == 1 else "false"
        op = f"QuantumArithmetic.AdditionOrig.OverflowBit({a}L,_,_,{ci_txt})"
        ans = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op})")
        assert ans == ((a+b+ci) >= N)


@pytest.mark.parametrize("n",  [1, 2, 3, 4, 5, 8, 16, 32])
def test_CompareConstLT(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(0, N-1)
        b = random.randint(0, N-1)
        op = f"QuantumArithmetic.AdditionOrig.CompareConstLT({a}L,_,_)"
        ans = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op})")
        assert ans == (a < b)

@pytest.mark.parametrize("n",  [1, 2, 3, 4, 5, 8, 16, 32])
def test_CompareConstLE(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(0, N-1)
        b = random.randint(0, N-1)
        op = f"QuantumArithmetic.AdditionOrig.CompareConstLE({a}L,_,_)"
        ans = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op})")
        assert ans == (a <= b)
