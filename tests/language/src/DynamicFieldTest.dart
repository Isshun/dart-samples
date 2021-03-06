// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that ensures that fields can be accessed dynamically.

class A extends C {
  var a;
  var b;
}

class C {
  foo() {
    print(a);
    return a;
  }
  bar() {
    print(b.a);
    return b.a;
  }
}

main() {
  var a = new A();
  a.a = 1;
  a.b = a;
  Expect.equals(1, a.foo());
  Expect.equals(1, a.bar());
}
