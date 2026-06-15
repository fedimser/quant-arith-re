import random

import pytest
from test_utils import run_op, run_unary_op


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 15, 16, 32, 64])
def test_AddConstant(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(-2 * N, 2 * N)
        b = random.randint(0, N - 1)
        op = f"QuantumArithmetic.ConstAdder.AddConstant({a}L,_)"
        assert run_unary_op(op, n, b) == (a + b) % N


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 32])
def test_OverflowBit(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(0, N - 1)
        b = random.randint(0, N - 1)
        ci = random.randint(0, 1)  # carry in.
        ci_txt = "true" if ci == 1 else "false"
        op = f"((b,ans)=>QuantumArithmetic.ConstAdder.OverflowBit({a}L,b,ans[0],{ci_txt}))"
        ans = run_op(op, [n, 1], [b, 0])
        assert ans == [b, (a + b + ci) >= N]


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 32])
def test_Comparisons(n: int):
    N = 2**n
    for _ in range(10):
        a = random.randint(0, N - 1)
        b = random.randint(0, N - 1)

        def _run(op) -> bool:
            ans = run_op(f"((b,ans)=>{op}({a}L,b,ans[0])", [n, 1], [b, 0])
            assert ans[0] == b
            return bool(ans[1])

        assert _run("QuantumArithmetic.ConstAdder.CompareByConstLT") == (a < b)
        assert _run("QuantumArithmetic.ConstAdder.CompareByConstLE") == (a <= b)
        assert _run("QuantumArithmetic.ConstAdder.CompareByConstGT") == (a > b)
        assert _run("QuantumArithmetic.ConstAdder.CompareByConstGE") == (a >= b)
