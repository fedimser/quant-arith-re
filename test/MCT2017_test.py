import random

import pytest

from superposition_test_utils import check_superposition_binary
from test_utils import ArithmeticOpTester


@pytest.mark.parametrize(
    "n1,n2",
    [
        (1, 1),
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
        (64, 64),
        (100, 100),
    ],
)
def test_Multiply(n1: int, n2: int):
    tester = ArithmeticOpTester("QuantumArithmetic.MCT2017.Multiply", [n1, n2, n1 + n2])
    for _ in range(5):
        a = random.randint(0, 2**n1 - 1)
        b = random.randint(0, 2**n2 - 1)
        assert tester.run([a, b, 0]) == [a, b, a * b]


def test_superposition():
    op = "QuantumArithmetic.MCT2017.Multiply"
    check_superposition_binary([8, 8, 16], op, lambda x, y: x * y)
