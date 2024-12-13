import pytest
from qsharp import init, eval
import random
import time


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
