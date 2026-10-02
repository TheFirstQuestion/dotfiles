# ruleid: three-param-limit-py
def too_many(a, b, c, d):
    return a + b + c + d


# ok: three-param-limit-py
def fine(a, b, c):
    return a + b + c


# ruleid: three-param-limit-py
def way_too_many(a, b, c, d, e, f, g):
    return a + b + c + d + e + f + g


# ok: three-param-limit-py
class K:
    def method(self, a, b, c):
        return a


class K2:
    # ruleid: three-param-limit-py
    def method(self, a, b, c, d):
        return a


# ok: three-param-limit-py
class K3:
    @classmethod
    def method(cls, a, b, c):
        return a


class K4:
    @classmethod
    # ruleid: three-param-limit-py
    def method(cls, a, b, c, d):
        return a


class K5:
    @staticmethod
    # ruleid: three-param-limit-py
    def method(a, b, c, d):
        return a


class K6:
    @staticmethod
    # ok: three-param-limit-py
    def method(a, b, c):
        return a
