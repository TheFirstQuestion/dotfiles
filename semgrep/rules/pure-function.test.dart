class Counter {
  int count = 0;
  final List<int> items = [];
  int _total = 0;
  final List<int> _cache = [];

  int pure(int a, int b) {
    // ok: impure-function-dart
    return a + b;
  }

  int pureArrow(int a) => a + 1;

  int pureLocalMutation(int a) {
    final local = <int>[];
    // ok: impure-function-dart
    local.add(a);
    return local.length;
  }

  void printsStuff() {
    // ruleid: impure-function-dart
    print('hello');
  }

  void debugPrints() {
    // ruleid: impure-function-dart
    debugPrint('hello');
  }

  void assignsField() {
    // ruleid: impure-function-dart
    this.count = 1;
  }

  void plusEqualsField() {
    // ruleid: impure-function-dart
    this.count += 1;
  }

  void minusEqualsField() {
    // ruleid: impure-function-dart
    this.count -= 1;
  }

  void addsToField() {
    // ruleid: impure-function-dart
    this.items.add(1);
  }

  void clearsField() {
    // ruleid: impure-function-dart
    this.items.clear();
  }

  void assignsPrivateField() {
    // ruleid: impure-function-dart
    _total = 1;
  }

  void incrementsPrivateField() {
    // ruleid: impure-function-dart
    _total++;
  }

  void addsToPrivateField() {
    // ruleid: impure-function-dart
    _cache.add(1);
  }

  void callsSetState() {
    // ruleid: impure-function-dart
    setState(() {});
  }

  void notifies() {
    // ruleid: impure-function-dart
    notifyListeners();
  }

  void readsClock() {
    // ruleid: impure-function-dart
    final now = DateTime.now();
  }

  void usesRandom() {
    // ruleid: impure-function-dart
    final r = Random();
  }

  void schedulesTimer() {
    // ruleid: impure-function-dart
    Timer(Duration.zero, () {});
  }

  void networkCall() {
    // ruleid: impure-function-dart
    http.get(uri);
  }

  void nestedInIf(bool flag) {
    if (flag) {
      // ruleid: impure-function-dart
      print('nested');
    }
  }

  void deeplyNested(int a) {
    for (var i = 0; i < a; i++) {
      if (i > 1) {
        // ruleid: impure-function-dart
        print(i);
      }
    }
  }

  void insideClosure(List<int> xs) {
    xs.forEach((e) {
      // ruleid: impure-function-dart
      print(e);
    });
  }

  int impureArrow(int a) =>
      // ruleid: impure-function-dart
      DateTime.now().year + a;
}

void topLevelImpure() {
  // ruleid: impure-function-dart
  print('top');
}

final impureClosure = () {
  // ruleid: impure-function-dart
  print('closure');
};

// ok: impure-function-dart
final topLevelInitializer = DateTime.now();
