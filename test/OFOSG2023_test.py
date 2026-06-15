import random

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize(
    "n1,n2",
    [
        (2, 2),
        (2, 16),
        (9, 2),
        (3, 3),
        (3, 4),
        (4, 4),
        (6, 8),
        (8, 8),
        (16, 16),
        (5, 16),
        (32, 32),
    ],
)
@pytest.mark.parametrize(
    "op",
    [
        "QuantumArithmetic.OFOSG2023.MultiplyWallaceTree",
        "QuantumArithmetic.OFOSG2023.MultiplyWallaceTreeIrr",
    ],
)
def test_MultiplyWallaceTree(n1: int, n2: int, op: str):
    tester = ArithmeticOpTester(op, [n1, n2, n1 + n2])
    for _ in range(5):
        a = random.randint(0, 2**n1 - 1)
        b = random.randint(0, 2**n2 - 1)
        assert tester.run([a, b, 0]) == [a, b, a * b]
