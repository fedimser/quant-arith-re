import math
import random

import qdk

CONTEXT = qdk.Context(project_root="./lib/")


def pow_mod(x, y, p):
    """Computes (x**y)%p."""
    a, x = 1, x % p
    while y > 0:
        if y & 1:
            a = (a * x) % p
        y = y >> 1
        x = (x * x) % p
    return a


def random_coprime(N):
    for _ in range(100):
        ans = random.randint(2, N - 1)
        if math.gcd(ans, N) == 1:
            return ans
    raise ValueError(f"No coprime for {N}")


class ArithmeticOpTester:
    """Tests arithmetic operation with fixed register sizes on many inputs."""

    def __init__(self, op: str, arg_sizes: int):
        self.arity = len(arg_sizes)
        args_expanded = ",".join(f"r[{i}]" for i in range(self.arity))
        op1 = f"r=>{op}({args_expanded})"

        CONTEXT.eval(f"""
        operation _RunOpOnInputs(inputs: BigInt[]) : BigInt[] {{
            return TestUtils.TestArithmeticOp({op1},{arg_sizes},inputs);           
        }}
        """)
        self.test_callable = CONTEXT.code._RunOpOnInputs

    def run(self, args: list[int]) -> list[int]:
        return self.test_callable(args)


def run_op(op: str, arg_sizes: list[int], args: list[int]) -> list[int]:
    return ArithmeticOpTester(op, arg_sizes).run(args)


def run_unary_op(op: str, arg_size: int, arg: int) -> int:
    return run_op(op, [arg_size], [arg])[0]
