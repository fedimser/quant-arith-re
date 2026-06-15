import random

import pytest

from test_utils import ArithmeticOpTester

@pytest.mark.parametrize("n", [2, 4, 8, 16, 24, 32, 63])
def test_compare(n: int):
    op = "((a,b,ans)=>QuantumArithmetic.Xin2018.CompareLess(a,b,ans[0]))"
    tester = ArithmeticOpTester(op, [n, n, 1])
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        assert tester.run([x, y, 0]) == [x, y, x < y]
