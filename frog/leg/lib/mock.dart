// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mocks of things that Leg cannot read directly.

// TODO(ahe): Remove this file.

class AssertionError {}
class TypeError extends AssertionError {}
class FallThroughError {}

// TODO(ahe): VM specfic exception?
class InternalError {
  const InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}

// TODO(ahe): VM specfic exception?
class StaticResolutionException implements Exception {}

void assert(condition) {}
