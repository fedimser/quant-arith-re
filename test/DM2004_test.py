import random

import pytest

from test_utils import ArithmeticOpTester

@pytest.mark.parametrize("n", [2, 8, 16, 32])
def test_Add(n: int):
    op = "((a,b,c)=>QuantumArithmetic.DM2004.Add(a,b,c[0]))"
    tester = ArithmeticOpTester(op, [n, n, 1])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        ans = tester.run([x, y, 0])
        assert ans == [x, (x + y) % (2**n), (x + y) // (2**n)]


@pytest.mark.parametrize("n", [2, 8, 16, 32])
def test_Add_Mod2N(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.DM2004.Add_Mod2N", [n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y]) == [x, (x + y) % (2**n)]