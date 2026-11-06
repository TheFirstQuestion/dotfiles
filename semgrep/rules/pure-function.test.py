# ok: impure-function-py
def pure(a, b):
    return a + b


# ruleid: impure-function-py
def prints_something(a):
    print(a)
    return a


class Counter:
    # ruleid: impure-function-py
    def __init__(self):
        self.total = 0
        self.items = []

    # ruleid: impure-function-py
    def add(self, a):
        self.total += a
        return self.total

    # ruleid: impure-function-py
    def record(self, item):
        self.items.append(item)
        return item

    # ok: impure-function-py
    def peek(self):
        return self.total


# ruleid: impure-function-py
def reads_clock():
    return time.time()


# ruleid: impure-function-py
def reads_file(path):
    return open(path)


# ok: impure-function-py
def builds_local_list(items):
    result = []
    result.append(items[0])
    return result
