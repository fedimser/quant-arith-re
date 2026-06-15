import random

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n", [2, 8, 32, 63, 64])
def test_Add_Mod2N(n: int):
    tester = ArithmeticOpTester("QuantumArithmetic.GKDKH2021.Add_Mod2N", [n, n, n])
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y, 0])[2] == (x + y) % (2**n)
