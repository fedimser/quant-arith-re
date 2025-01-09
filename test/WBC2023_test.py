import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root=".")


# @pytest.mark.parametrize("n", [6])
# @pytest.mark.parametrize("radix", [3])
# def test_Add(n: int, radix: int):
#     op = "QuantumArithmetic.WBC2023_new.Add"
#     for _ in range(10):
#         x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
#         ans = eval(f"TestUtils.BinaryOpInPlaceRadix({n},{x},{y},{radix},{op})")
#         assert ans == (x+y) % 2**n


@pytest.mark.parametrize("n", [4, 5, 8, 16, 31, 32, 63])
def test_Add(n: int):
    op = "QuantumArithmetic.WBC2023.Add"
    radix = 3
    for _ in range(5):
        a = random.randint(0, 2 ** (n - 1))
        b = random.randint(0, 2 ** (n - 1))
        ans = eval(
            f"QuantumArithmetic.WBC2023Test.BinaryOpRadix({n},{a}L,{b}L,{radix},{op})"
        )
        expected = (a + b) % (2**n)
        assert ans == expected
