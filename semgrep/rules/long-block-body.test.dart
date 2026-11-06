void blocks(int a, List<int> xs) {
  // ruleid: long-block-body-dart
  if (a > 0) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  }

  // ok: long-block-body-dart
  if (a > 1) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
  }

  // ruleid: long-block-body-dart
  if (a > 2) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  } else {
    print(0);
  }

  // ruleid: long-block-body-dart
  while (a > 3) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  }

  // ok: long-block-body-dart
  while (a > 4) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
  }

  // ruleid: long-block-body-dart
  for (var i = 0; i < 3; i++) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  }

  // ok: long-block-body-dart
  for (var i = 0; i < 3; i++) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
  }

  // ruleid: long-block-body-dart
  for (var x in xs) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  }

  // ruleid: long-block-body-dart
  for (final x in xs) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  }

  // ok: long-block-body-dart
  for (final x in xs) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
  }

  int bare;
  // ruleid: long-block-body-dart
  for (bare in xs) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    print(6);
  }

  // ruleid: long-block-body-dart
  if (a > 5) {
    var x = 1;
    final y = 2;
    print(x);
    if (y > 1) {
      print(2);
    }
    for (var i = 0; i < 2; i++) {
      print(i);
    }
    return;
  }

  // ok: long-block-body-dart
  if (a > 6) {
    print(
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
    );
    print(2);
    print(3);
    print(4);
    print(5);
  }

  // ruleid: long-block-body-dart
  if (a > 7) {
    print(1);
    print(2);
    print(3);
    print(4);
    print(5);
    // ok: long-block-body-dart
    if (a > 8) {
      print(6);
    }
  }
}
