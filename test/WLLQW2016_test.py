import random

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [1, 2, 3, 9, 16, 32])
def test_Add(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.WLLQW2016.Add_Mod2N", [n, n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y, 0]) == [x, y, (x + y) % 2**n]
