class Order {
  Order(this.customer);

  final Customer customer;

  void placeFine(Arg arg) {
    arg.validate();
    customer.notify();
    final wallet = Wallet();
    wallet.charge();
    // ok: law-of-demeter-dart
    total();
  }

  void placeBad() {
    // ruleid: law-of-demeter-dart
    customer.getWallet().charge();
  }

  void placeBadArg(Arg arg) {
    // ruleid: law-of-demeter-dart
    arg.getWallet().charge();
  }

  void placeBadNew() {
    // ruleid: law-of-demeter-dart
    Wallet().open().charge();
  }

  void placeBadNullAwareFirst(Arg? arg) {
    // ruleid: law-of-demeter-dart
    arg?.getWallet().charge();
  }

  void placeBadNullAwareSecond(Arg arg) {
    // ruleid: law-of-demeter-dart
    arg.getWallet()?.charge();
  }

  void placeBadBang(Arg? arg) {
    // ruleid: law-of-demeter-dart
    arg!.getWallet().charge();
  }

  void flutterNavigator(BuildContext context) {
    // ruleid: law-of-demeter-dart
    Navigator.of(context).push(route);
  }

  void fluentChain(List<int> xs) {
    // ruleid: law-of-demeter-dart
    final evens = xs.where((x) => x.isEven).toList();
  }

  void propertyChainOnly(Arg arg) {
    // ok: law-of-demeter-dart
    arg.wallet.charge();
  }

  void cascade(Arg arg) {
    // ok: law-of-demeter-dart
    arg.getWallet()..open()..charge();
  }
}

void storesThenCalls(Arg a) {
  final b = a.getB();
  // ok: law-of-demeter-dart
  b.getC();
}
