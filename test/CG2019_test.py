import pytest
from qsharp import init, eval
import random

from superposition_test_utils import check_superposition_binary


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64, 80, 100])
def test_MultiplySchoolbook(n: int):
    op = "QuantumArithmetic.CG2019.MultiplySchoolbook"
    x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
    ans = eval(f"TestUtils.TestMultiply({n},{n},{x}L,{y}L,{op})")
    assert ans == x*y 


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64, 80, 100])
def test_MultiplyKaratsuba(n: int):
    op = "QuantumArithmetic.CG2019.MultiplyKaratsuba"
    x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
    ans = eval(f"TestUtils.TestMultiply({n},{n},{x}L,{y}L,{op})")
    assert ans == x*y 


def test_superposition():
    n = 8
    op = "QuantumArithmetic.CG2019.MultiplyKaratsuba"
    classical_op = lambda x, y: x*y
    check_superposition_binary([n,n,2*n], op, classical_op)
