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
        ans = eval(f"TestUtils.TestMultiply({n},{n},{a}L,{b}L,{op})")
        expected = a*b
        assert ans == expected


@pytest.mark.parametrize("n", [2, 4, 6, 8, 16, 32, 64])
def test_CyclicShiftRight(n: int):
    for _ in range(5):
        x = random.randint(0, 2**(n)-1)
        r = random.randint(-n, n)
        op = f"QuantumArithmetic.NZLS2023.CyclicShiftRight(_,{r})"
        ans = eval(f"TestUtils.UnaryOpInPlace({n},{x}L,{op})")
        r1 = r % n
        expected = (x >> (n-r1)) + ((x % (2**(n-r1))) << r1)
        assert ans == expected

@pytest.mark.parametrize("n", [2, 4, 6, 8, 16, 32, 64])
def test_Butterfly(n: int):
    assert n % 2 == 0
    N = 2**(n//2)+1  # modulo.
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        op = "QuantumArithmetic.NZLS2023Test.TestButterfly"
        ans1, ans2 = eval(f"{op}({n},{a}L,{b}L)")
        print("N=", N)
        assert ans1 % N == (a+b) % N
        # TODO: fix adder so this assertion passed.
        # assert ans2 % N == (a-b) % N   
