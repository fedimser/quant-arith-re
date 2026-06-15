import random

import pytest

from test_utils import ArithmeticOpTester

@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 19])
def test_Add(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.TR2013.Add", [n, n])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        assert tester.run([a, b]) == [a, (a + b) % (2**n)]


@pytest.mark.parametrize("n", [3, 4, 5, 8, 16])
def test_AddWithCarry(n: int):
    op = "((a,b,c)=>QuantumArithmetic.TR2013.AddWithCarry(a,b,c[0]))"
    tester = ArithmeticOpTester(op, [n, n, 1])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        c = random.randint(0, 1)
        assert tester.run([a, b, c]) == [a, (a + b + c) % (2**n), c]
