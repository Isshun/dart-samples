// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("frog_test_config");

#import("../../../tools/testing/dart/test_suite.dart");

class FrogNativeTestSuite extends StandardTestSuite {
  FrogNativeTestSuite(Map configuration)
      : super(configuration,
              "frog_native",
              "frog/tests/native/src",
              ["frog/tests/native/native.status"]);
}
