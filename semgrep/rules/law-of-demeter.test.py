class Order:
    def __init__(self, customer):
        self.customer = customer

    def place_fine(self, arg):
        arg.validate()
        self.customer.notify()
        wallet = Wallet()
        wallet.charge()
        # ok: law-of-demeter-py
        return self.total()

    def place_bad(self, arg):
        # ruleid: law-of-demeter-py
        return self.customer.get_wallet().charge()

    def place_bad_arg(self, arg):
        # ruleid: law-of-demeter-py
        return arg.get_wallet().charge()

    def place_bad_new(self):
        # ruleid: law-of-demeter-py
        return Wallet().open().charge()


def stores_then_calls(a):
    b = a.get_b()
    # ok: law-of-demeter-py
    return b.get_c()
