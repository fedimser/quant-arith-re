"""Functional tests for addition algorihtms."""

import pytest
from qsharp import init, eval
import random


@pytest.mark.parametrize("n", [2, 3, 5, 8])
def test_addition(n: int):
    init(project_root='.')
    op = "QuantumArithmetic.IncByLE"
    for _ in range(10):
        x = random.randint(0, 2**n-1)
        y = random.randint(0, 2**n-1)
        ans = eval(f"""
            QuantumArithmetic.Test.PerformArithmeticOperationInPlace({n},{n},{x},{y},{op})
        """)
        expected = (x+y) % (2**n)
        assert ans == expected
