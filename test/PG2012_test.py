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
        t0 = time.time()
        ans = eval(f"QuantumArithmetic.PG2012Test.TestFADD({n},{a},{b})")
        print(n, time.time()-t0)
        expected = (a+b) % (2**n)
        assert ans == expected


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5])
def test_FMAC(n: int):
    for _ in range(5):
        a = random.randint(-2**n, 2**n-1)
        b = random.randint(0, 2**n-1)
        x = random.randint(0, 2**n-1)
        print(n, a, b, x)
        t0 = time.time()
        ans = eval(f"QuantumArithmetic.PG2012Test.TestFMAC({n},{a},{b},{x})")
        print(n, time.time()-t0)
        expected = (b+a*x) % (2**(2*n))
        assert ans == expected
