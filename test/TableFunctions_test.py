import math

import pytest

from test_utils import ArithmeticOpTester


@pytest.mark.parametrize("n1,n2", [(2, 3), (3, 13), (4, 41)])
def test_Factorial(n1: int, n2: int):
    op = "QuantumArithmetic.TableFunctions.Factorial"
    tester = ArithmeticOpTester(op, [n1, n2])
    for i in range(2**n1):
        assert tester.run([i, 0]) == [i, math.factorial(i)]
