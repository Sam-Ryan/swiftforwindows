//===--- BridgeNonVerbatim.swift - Array bridging implementation test -----===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
//  When a ContiguousArray<T> is bridged to Objective-C, and T isn't
//  "bridged verbatim," Cocoa operations like objectAtIndex may have
//  to conjure up an object to return, and this object is expected to
//  outlive the array.  
//
//===----------------------------------------------------------------------===//
// RUN: %target-run-stdlib-swift %s | FileCheck %s
// REQUIRES: executable_test
//
// REQUIRES: objc_interop

import Swift
import SwiftShims
import ObjectiveC

// FIXME: Should go into the standard library.
public extension _ObjectiveCBridgeable {
  static func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectiveCType?)
      -> Self {
    var result: Self? = nil
    _forceBridgeFromObjectiveC(source!, result: &result)
    return result!
  }
}

//===--- class Tracked ----------------------------------------------------===//
// Instead of testing with Int elements, we use this wrapper class
// that can help us track allocations and find issues with object
// lifetime inside Array implementations.
var trackedCount = 0
var nextTrackedSerialNumber = 0

final class Tracked : ForwardIndex, CustomStringConvertible {
  required init(_ value: Int) {
    trackedCount += 1
    nextTrackedSerialNumber += 1
    serialNumber = nextTrackedSerialNumber
    self.value = value
  }
  
  deinit {
    assert(serialNumber > 0, "double destruction!")
    trackedCount -= 1
    serialNumber = -serialNumber
  }

  var description: String {
    assert(serialNumber > 0, "dead Tracked!")
    return value.description
  }

  func successor() -> Self {
    return self.dynamicType.init(self.value.successor())
  }

  var value: Int
  var serialNumber: Int
}

func == (x: Tracked, y: Tracked) -> Bool {
  return x.value == y.value
}

struct X : _ObjectiveCBridgeable {
  static func _isBridgedToObjectiveC() -> Bool {
    return true
  }
  
  init(_ value: Int) {
    self.value = value
  }

  func _bridgeToObjectiveC() -> Tracked {
    return Tracked(value)
  }

  static func _forceBridgeFromObjectiveC(
    _ x: Tracked,
    result: inout X?
  ) {
    result = X(x.value)
  }

  static func _conditionallyBridgeFromObjectiveC(
    _ x: Tracked,
    result: inout X?
  ) -> Bool {
    result = X(x.value)
    return true
  }

  var value: Int
}

// CHECK: testing...
print("testing...")

func testScope() {
  let a = [X(1), X(2), X(3)]
  let nsx = a._buffer._asCocoaArray()

  // construction of these tracked objects is lazy
  // CHECK-NEXT: trackedCount = 0 .
  print("trackedCount = \(trackedCount) .")

  // We can get a single element out
  // CHECK-NEXT: nsx[0]: 1 .
  let one = nsx.objectAt(0) as! Tracked
  print("nsx[0]: \(one.value) .")

  // We can get the element again, but it may not have the same identity
  // CHECK-NEXT: object identity matches?
  let anotherOne = nsx.objectAt(0) as! Tracked
  print("object identity matches? \(one === anotherOne)")

  // Because the elements come back at +0, we really don't want to
  // treat them as objects, or we'll get double deletion
  var objects: [Int] = [0, 0]

  objects.withUnsafeMutableBufferPointer {
    // FIXME: Can't elide signature and use $0 here <rdar://problem/17770732> 
    (buf: inout UnsafeMutableBufferPointer<Int>) -> () in
    nsx.getObjects(
      UnsafeMutablePointer<AnyObject>(buf.baseAddress!),
      range: _SwiftNSRange(location: 1, length: 2))
  }

  // CHECK-NEXT: getObjects yields them at +0: true
  var x = objects[0]
  print("getObjects yields them at +0: "
    + "\(_isUnique_native(&x))")
}

autoreleasepool() {
  testScope()
}

// CHECK-NEXT: leaks = 0 .
print("leaks = \(trackedCount) .")

