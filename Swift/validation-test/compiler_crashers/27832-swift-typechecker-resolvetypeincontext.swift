// This source file is part of the Swift.org open source project
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

// RUN: not --crash %target-swift-frontend %s -parse
// ASAN Output: stack-overflow on address 0x7ffd2c334fb0 (pc 0x0000008ecf9e bp 0x7ffd2c3357f0 sp 0x7ffd2c334fa0 T0)
enum A
protocol A{
associatedtype f:a
func a<T where f:d
