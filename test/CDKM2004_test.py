import random

import pytest
from test_utils import ArithmeticOpTester
from superposition_test_utils import check_superposition_binary_inplace


@pytest.mark.parametrize("n", [1, 2, 3, 5, 8, 16, 32, 63])
@pytest.mark.parametrize(
    "op",
    [
        "QuantumArithmetic.CDKM2004.Add",
        "QuantumArithmetic.CDKM2004.AddUnoptimized",
    ],
)
def test_Add(n: int, op: str):
    tester = ArithmeticOpTester(op, [n, n])
    for _ in range(10):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        assert tester.run([x, y]) == [x, (x + y) % (2**n)]


@pytest.mark.parametrize(
    "op",
    [
        "QuantumArithmetic.CDKM2004.Add",
        "QuantumArithmetic.CDKM2004.AddUnoptimized",
    ],
)
def test_superposition(op: str):
    n = 8
    classical_op = lambda x, y: (x + y) % (2**n)
    check_superposition_binary_inplace(n, op, classical_op)
