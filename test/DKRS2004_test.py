import pytest
import random

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 63])
def test_Add(n: int):
    op = "QuantumArithmetic.DKRS2004.Add"
    tester = ArithmeticOpTester(op, [n, n])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        ans = tester.run([a, b])
        assert ans == [a, (a + b) % (2**n)]


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 62])
def test_AddWithCarry(n: int):
    op = "((a,b,c)=>QuantumArithmetic.DKRS2004.AddWithCarry(a,b,c[0]))"
    tester = ArithmeticOpTester(op, [n, n, 1])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        ans = tester.run([a, b, 0])
        assert ans == [a, (a + b) % (2**n), (a + b) // (2**n)]
