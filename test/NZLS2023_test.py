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


@pytest.mark.parametrize("n", [2, 4, 6]) # TODO: make work for n>=8.
def test_CyclicShiftRight(n: int):
    for _ in range(105):
        x = random.randint(0, 2**(n)-1)
        r = random.randint(-n, n)
        op = f"QuantumArithmetic.NZLS2023.CyclicShiftRight(_,{r})"
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        r1 = r % n
        expected = (x >> (n-r1)) + ((x % (2**(n-r1))) << r1)
        assert ans == expected
