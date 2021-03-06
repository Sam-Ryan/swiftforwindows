// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

// RUN: not %target-swift-frontend %s -parse
// REQUIRES: objc_interop

// Issue found by https://github.com/PartiallyFinite (Greg Omelaenko)

import Foundation

protocol P {
  static func f() -> Self
  static func g() -> Self
}

extension P {
  static func f() -> P {
    return g()
  }
}

extension NSData: P {
  static func g() -> Self {
    return self.init()
  }
}

