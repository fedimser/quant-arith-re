import pytest
from qsharp import init, eval
import random
import math


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [2, 3, 5, 8, 10])
def test_FADD(n: int):
    for _ in range(5):
        a, b = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        expected = (a+b) % (2**n)
        ans1 = eval(f"QuantumArithmetic.PG2012Test.TestFADD({n},{a},{b})")
        assert ans1 == expected
        ans2 = eval(f"QuantumArithmetic.PG2012Test.TestFADD2({n},{a},{b})")
        assert ans2 == expected


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5])
def test_FMAC(n: int):
    for _ in range(5):
        a = random.randint(-2**n, 2**n-1)
        b = random.randint(0, 2**n-1)
        x = random.randint(0, 2**n-1)
        print(n, a, b, x)
        ans = eval(f"QuantumArithmetic.PG2012Test.TestFMAC({n},{a},{b},{x})")
        expected = (b+a*x) % (2**(2*n))
        assert ans == expected


@pytest.mark.parametrize("n", [1, 2, 3, 4])
def test_GMFDIV(n: int):
    for _ in range(5):
        b = random.randint(1, 2**n-1)
        a = random.randint(0, (b*2**n)-1)
        assert 0 <= a//b < 2**n
        q, r = eval(f"QuantumArithmetic.PG2012Test.TestGMFDIV({n},{a},{b})")
        assert (q, r) == (a//b, a % b)


@pytest.mark.parametrize("n,mod", [(2, 3), (3, 6), (3, 7), (4, 13)])
def test_MACMOD(n: int, mod: int):
    assert 1 <= mod < 2**n
    for _ in range(5 if n <= 3 else 1):
        a = random.randint(1, mod-1)
        b_max = min(2**n, int(math.ceil(2**n*mod/a)))-1
        b = random.randint(0, b_max)
        ans = eval(
            f"QuantumArithmetic.PG2012Test.TestFMAC_MOD2({n},{a},{b},{mod})")
        assert ans == (a*b) % mod


def test_MUL_MOD():
    for i in range(1, 7):
        ans = eval(f"QuantumArithmetic.PG2012Test.TestFMUL_MOD2(3,5,{i},7)")
        assert ans == (i*5) % 7


@pytest.mark.parametrize("n,a,b,N", [(2, 2, 2, 3), (3, 6, 5, 7)])
def test_EXP_MOD(n, a, b, N):
    op = "QuantumArithmetic.PG2012.EXP_MOD"
    ans = eval(f"TestUtils.TestModExp({n},{a}L,{b}L,{N}L,{op})")
    assert ans == (a**b) % N


@pytest.mark.parametrize("n",  [1, 2, 3, 4, 5, 8])
def test_AddConstantQFT(n: int):
    N = 2**n
    for _ in range(5):
        a = random.randint(-2*N, 2*N)
        b = random.randint(0, N-1)
        op = f"QuantumArithmetic.PG2012.AddConstantQFT({a}L,_)"
        ans = eval(f"TestUtils.UnaryOpInPlaceCtl({n},{b}L,{op})")
        assert ans == (a+b) % N