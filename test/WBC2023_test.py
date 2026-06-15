import random

import pytest

from superposition_test_utils import check_superposition_binary
from test_utils import ArithmeticOpTester




@pytest.mark.parametrize("radix", [3, 4, 5, 6, 7, 8, 9, 10])
@pytest.mark.parametrize("n", [3, 4, 5, 8, 12, 30])
def test_Add(n: int, radix: int):
    op = f"QuantumArithmetic.WBC2023.Add(_,_,_,{radix})"
    if (n >= radix) and (n / radix < 10):
        tester = ArithmeticOpTester(op, [n, n, n])
        for _ in range(5):
            a = random.randint(0, 2 ** (n - 1))
            b = random.randint(0, 2 ** (n - 1))
            assert tester.run([a, b, 0]) == [a, b, (a + b) % (2**n)]



def test_superposition():
    n = 8
    radix = 3
    op = f"QuantumArithmetic.WBC2023.Add(_,_,_,{radix})"
    classical_op = lambda x, y: (x + y) % (2**n)
    check_superposition_binary([n, n, n], op, classical_op)
