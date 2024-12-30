import random
import math


def pow_mod(x, y, p):
    """Computes (x**y)%p."""
    a, x = 1, x % p
    while (y > 0):
        if (y & 1):
            a = (a * x) % p
        y = y >> 1
        x = (x * x) % p
    return a


def random_coprime(N):
    for _ in range(100):
        ans = random.randint(2, N-1)
        if math.gcd(ans, N) == 1:
            return ans
    raise ValueError(f"No coprime for {N}")
