import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [1, 2, 5, 8, 16])
def test_MultiplyTextbook(n: int):
    op = "QuantumArithmetic.NZLS2023.MultiplyTextbook"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.TestMultiply({n},{a}L,{b}L,{op})")
        expected = a*b
        assert ans == expected
