proc fib2(term, val, prev: int): int =
 if term == 0: prev
 else: fib2(term - 1, val + prev, val)

proc fib(term: int): int {.exportc.} = fib2(term, 1, 0)