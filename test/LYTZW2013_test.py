import random

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("op", [
    "QuantumArithmetic.LYTZW2013.Increment_v1",
    "QuantumArithmetic.LYTZW2013.Increment_v2",
    "QuantumArithmetic.LYTZW2013.Increment_v3",
])
@pytest.mark.parametrize("n", [1, 2, 3, 4, 5])
def test_Increment_Exhaustive(op: str, n: int):
    tester = ArithmeticOpTester(op, [n])
    N = 2**n
    for x in range(N):
        assert tester.run([x])[0] == (x + 1) % N


@pytest.mark.parametrize("op", [
    "QuantumArithmetic.LYTZW2013.Increment_v1",
    "QuantumArithmetic.LYTZW2013.Increment_v2",
    "QuantumArithmetic.LYTZW2013.Increment_v3",
])
@pytest.mark.parametrize("n", [8, 16, 32, 64, 65])
def test_Increment(op: str, n: int):
    tester = ArithmeticOpTester(op, [n])
    N = 2**n
    for _ in range(5):
        x = random.randint(0, N - 1)
        assert tester.run([x])[0] == (x + 1) % N
