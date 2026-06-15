import random

import pytest

from superposition_test_utils import check_superposition_binary
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [2, 3, 4, 5, 8, 9, 16, 17, 32, 33])
def test_Add(n: int):
    op = "((a,b,c,d)=>QuantumArithmetic.SC2023.Add(a,b,c,d[0]))"
    tester = ArithmeticOpTester(op, [n, n, n, 1])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        ans = tester.run([x, y, 0, 0])
        assert ans == [x, (x + y) % (2**n), y, (x + y) // (2**n)]


@pytest.mark.parametrize("n", [3, 32, 63])
def test_Add_Mod2N(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.SC2023.Add_Mod2N", [n, n, n])
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y, 0]) == [x, y, (x + y) % (2**n)]


def test_superposition():
    n = 8
    op = "QuantumArithmetic.SC2023.Add_Mod2N"
    classical_op = lambda x, y: (x + y) % (2**n)
    check_superposition_binary([n, n, n], op, classical_op)
