//===--- ExistentialCollection.swift --------------------------------------===//
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
// RUN: %target-run-simple-swift
// REQUIRES: executable_test

import StdlibUnittest
import StdlibCollectionUnittest


// Check that the generic parameter is called 'Element'.
protocol TestProtocol1 {}

extension AnyIterator where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnySequence where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnyForwardCollection where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnyBidirectionalCollection where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

extension AnyRandomAccessCollection where Element : TestProtocol1 {
  var _elementIsTestProtocol1: Bool {
    fatalError("not implemented")
  }
}

var tests = TestSuite("ExistentialCollection")

tests.test("AnyIterator") {
  func digits() -> AnyIterator<String> {
    let lazyStrings = (0..<5).lazy.map { String($0) }
    
    // This is a really complicated type of no interest to our
    // clients.
    let iterator: LazyMapIterator<RangeIterator<Int>, String> =
      lazyStrings.makeIterator()
    return AnyIterator(iterator)
  }
  expectEqual(["0", "1", "2", "3", "4"], Array(digits()))

  var x = 7
  let iterator = AnyIterator<Int> {
    if x >= 15 { return nil }
    x += 1
    return x-1
  }
  expectEqual([ 7, 8, 9, 10, 11, 12, 13, 14 ], Array(iterator))
}

let initialCallCounts = [
  "successor": 0, "predecessor": 0,
  "_successorInPlace": 0, "_predecessorInPlace": 0,
  "advanced(by:)": 0, "distance(to:)": 0
]

var callCounts = initialCallCounts
  
struct InstrumentedIndex<I : RandomAccessIndex> : RandomAccessIndex {
  typealias Distance = I.Distance

  var base: I
  
  init(_ base: I) {
    self.base = base
  }
  
  static func resetCounts() {
    callCounts = initialCallCounts
  }
  
  func successor() -> InstrumentedIndex {
    callCounts["successor"]! += 1
    return InstrumentedIndex(base.successor())
  }
  
  mutating func _successorInPlace() {
    callCounts["_successorInPlace"]! += 1
    base._successorInPlace()
  }
  
  func predecessor() -> InstrumentedIndex {
    callCounts["predecessor"]! += 1
    return InstrumentedIndex(base.predecessor())
  }
  
  mutating func _predecessorInPlace() {
    callCounts["_predecessorInPlace"]! += 1
    base._predecessorInPlace()
  }
  
  func advanced(by distance: Distance) -> InstrumentedIndex {
    callCounts["advanced(by:)"]! += 1
    return InstrumentedIndex(base.advanced(by: distance))
  }
  
  func distance(to other: InstrumentedIndex) -> Distance {
    callCounts["distance(to:)"]! += 1
    return base.distance(to: other.base)
  }
}

tests.test("AnySequence.init(Sequence)") {
  do {
    let base = MinimalSequence<OpaqueValue<Int>>(elements: [])
    var s = AnySequence(base)
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence([], s, resiliencyChecks: .none) { $0.value == $1.value }
  }
  do {
    let intData = [ 1, 2, 3, 5, 8, 13, 21 ]
    let data = intData.map(OpaqueValue.init)
    let base = MinimalSequence(elements: data)
    var s = AnySequence(base)
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence(data, s, resiliencyChecks: .none) { $0.value == $1.value }
  }
}

tests.test("AnySequence.init(() -> Generator)") {
  do {
    var s = AnySequence {
      return MinimalIterator<OpaqueValue<Int>>([])
    }
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence([], s, resiliencyChecks: .none) { $0.value == $1.value }
  }
  do {
    let intData = [ 1, 2, 3, 5, 8, 13, 21 ]
    let data = intData.map(OpaqueValue.init)
    var s = AnySequence {
      return MinimalIterator(data)
    }
    expectType(AnySequence<OpaqueValue<Int>>.self, &s)
    checkSequence(data, s, resiliencyChecks: .none) { $0.value == $1.value }
  }
}

tests.test("ForwardIndex") {
  var i = AnyForwardIndex(InstrumentedIndex(0))
  i = i.successor()
  expectEqual(1, callCounts["successor"])
  expectEqual(0, callCounts["_successorInPlace"])
  i._successorInPlace()
  expectEqual(1, callCounts["successor"])
  expectEqual(1, callCounts["_successorInPlace"])
  var x = i
  i = i.successor()
  expectEqual(2, callCounts["successor"])
  expectEqual(1, callCounts["_successorInPlace"])
  _blackHole(x)
}

tests.test("BidirectionalIndex") {
  var i = AnyBidirectionalIndex(InstrumentedIndex(0))
  expectEqual(0, callCounts["predecessor"])
  expectEqual(0, callCounts["_predecessorInPlace"])

  i = i.predecessor()
  expectEqual(1, callCounts["predecessor"])
  expectEqual(0, callCounts["_predecessorInPlace"])
  i._predecessorInPlace()
  expectEqual(1, callCounts["predecessor"])
  expectEqual(1, callCounts["_predecessorInPlace"])
  var x = i
  i = i.predecessor()
  expectEqual(2, callCounts["predecessor"])
  expectEqual(1, callCounts["_predecessorInPlace"])
  _blackHole(x)
}

tests.test("ForwardCollection") {
  let a0: ContiguousArray = [1, 2, 3, 5, 8, 13, 21]
  let fc0 = AnyForwardCollection(a0)
  let a1 = ContiguousArray(fc0)
  expectEqual(a0, a1)
  for e in a0 {
    let i = fc0.index(of: e)
    expectNotEmpty(i)
    expectEqual(e, fc0[i!])
  }
  for i in fc0.indices {
    expectNotEqual(fc0.endIndex, i)
    expectEqual(1, fc0.indices.filter { $0 == i }.count)
  }
}

tests.test("BidirectionalCollection") {
  let a0: ContiguousArray = [1, 2, 3, 5, 8, 13, 21]
  let fc0 = AnyForwardCollection(a0.lazy.reversed())
  
  let bc0_ = AnyBidirectionalCollection(fc0)         // upgrade!
  expectNotEmpty(bc0_)
  let bc0 = bc0_!
  expectTrue(fc0 === bc0)

  let fc1 = AnyForwardCollection(a0.lazy.reversed()) // new collection
  expectFalse(fc1 === fc0)

  let fc2 = AnyForwardCollection(bc0)                // downgrade
  expectTrue(fc2 === bc0)
  
  let a1 = ContiguousArray(bc0.lazy.reversed())
  expectEqual(a0, a1)
  for e in a0 {
    let i = bc0.index(of: e)
    expectNotEmpty(i)
    expectEqual(e, bc0[i!])
  }
  for i in bc0.indices {
    expectNotEqual(bc0.endIndex, i)
    expectEqual(1, bc0.indices.filter { $0 == i }.count)
  }
  
  // Can't upgrade a non-random-access collection to random access
  let s0 = "Hello, Woyld".characters
  let bc1 = AnyBidirectionalCollection(s0)
  let fc3 = AnyForwardCollection(bc1)
  expectTrue(fc3 === bc1)
  expectEmpty(AnyRandomAccessCollection(bc1))
  expectEmpty(AnyRandomAccessCollection(fc3))
}

tests.test("RandomAccessCollection") {
  let a0: ContiguousArray = [1, 2, 3, 5, 8, 13, 21]
  let fc0 = AnyForwardCollection(a0.lazy.reversed())
  let rc0_ = AnyRandomAccessCollection(fc0)         // upgrade!
  expectNotEmpty(rc0_)
  let rc0 = rc0_!
  expectTrue(rc0 === fc0)

  let bc1 = AnyBidirectionalCollection(rc0)         // downgrade
  expectTrue(bc1 === rc0)

  let fc1 = AnyBidirectionalCollection(rc0)         // downgrade
  expectTrue(fc1 === rc0)
  
  let a1 = ContiguousArray(rc0.lazy.reversed())
  expectEqual(a0, a1)
  for e in a0 {
    let i = rc0.index(of: e)
    expectNotEmpty(i)
    expectEqual(e, rc0[i!])
  }
  for i in rc0.indices {
    expectNotEqual(rc0.endIndex, i)
    expectEqual(1, rc0.indices.filter { $0 == i }.count)
  }
}

runAllTests()
