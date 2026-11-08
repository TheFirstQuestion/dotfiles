// ruleid: three-param-limit-dart
int tooMany(int a, int b, int c, int d) {
  return a + b + c + d;
}

// ok: three-param-limit-dart
int fine(int a, int b, int c) {
  return a + b + c;
}

// ruleid: three-param-limit-dart
int wayTooMany(int a, int b, int c, int d, int e, int f, int g) {
  return a + b + c + d + e + f + g;
}

// ruleid: three-param-limit-dart
int arrowTooMany(int a, int b, int c, int d) => a + b + c + d;

// ok: three-param-limit-dart
int arrowFine(int a, int b) => a + b;

// ruleid: three-param-limit-dart
Future<int> asyncTooMany(int a, int b, int c, int d) async {
  return a;
}

// ok: three-param-limit-dart
Future<int> asyncFine(int a, int b, int c) async {
  return a;
}

// ruleid: three-param-limit-dart
untypedTooMany(a, b, c, d) {
  return a;
}

// ruleid: three-param-limit-dart
void namedTooMany({required int a, required int b, required int c, required int d}) {}

// ok: three-param-limit-dart
void namedFine({required int a, required int b, required int c}) {}

// ruleid: three-param-limit-dart
void mixedTooMany(int a, int b, {int? c, int? d}) {}

class Service {
  // ruleid: three-param-limit-dart
  int method(int a, int b, int c, int d) {
    return a;
  }

  // ok: three-param-limit-dart
  int methodFine(int a, int b, int c) {
    return a;
  }

  // ruleid: three-param-limit-dart
  static int staticMethod(int a, int b, int c, int d) => a;

  // ok: three-param-limit-dart
  Service(this.a, this.b, this.c, this.d);

  final int a, b, c, d;
}

class Widget {
  // ok: three-param-limit-dart
  const Widget({super.key, required this.a, required this.b, required this.c, required this.d});

  final int a, b, c, d;
}

void closures(List<int> xs) {
  // ruleid: three-param-limit-dart
  xs.forEach((a, b, c, d) {
    print(a);
  });

  // ok: three-param-limit-dart
  xs.forEach((a, b, c) {
    print(a);
  });

  // ruleid: three-param-limit-dart
  final arrow = (int a, int b, int c, int d) => a;

  // ok: three-param-limit-dart
  final arrowFineClosure = (int a, int b) => a;
}
