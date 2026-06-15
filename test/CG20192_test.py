import random

import pytest
from test_utils import CONTEXT, ArithmeticOpTester, random_coprime


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64])
def test_Multiply(n: int):
    op = CONTEXT.code.QuantumArithmetic.CG20192.Multiply
    x, y, t = (
        random.randint(0, 2**n - 1),
        random.randint(0, 2**n - 1),
        random.randint(0, 2**n - 1),
    )
    ans = op(n, n, t, x, y)
    assert ans == x * y + t


@pytest.mark.parametrize("n", [3, 4, 8, 16, 32])
def test_ModExp(n: int):
    N = 1 + 2 * random.randint(1, 2 ** (n - 1) - 1)
    a = random_coprime(N)
    op = f"QuantumArithmetic.CG20192.ModExpWindow(_,_,{a}L,{N}L,2,2)"
    tester = ArithmeticOpTester(op, [n, n])
    x = random.randint(0, 2**n - 1)
    assert tester.run([x, 0]) == [x, pow(a, x, mod=N)]
