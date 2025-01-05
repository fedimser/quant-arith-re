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
def test_Comparisons(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(0, N-1)
        b = random.randint(0, N-1)
        op1 = f"QuantumArithmetic.AdditionOrig.CompareByConstLT({a}L,_,_)"
        op2 = f"QuantumArithmetic.AdditionOrig.CompareByConstLE({a}L,_,_)"
        op3 = f"QuantumArithmetic.AdditionOrig.CompareByConstGT({a}L,_,_)"
        op4 = f"QuantumArithmetic.AdditionOrig.CompareByConstGE({a}L,_,_)"
        ans1 = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op1})")
        ans2 = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op2})")
        ans3 = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op3})")
        ans4 = eval(f"TestUtils.UnaryPredicateCtl({n},{b}L,{op4})")
        assert ans1 == (a < b)
        assert ans2 == (a <= b)
        assert ans3 == (a > b)
        assert ans4 == (a >= b)
        
 
