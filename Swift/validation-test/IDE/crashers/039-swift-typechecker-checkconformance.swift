// RUN: not --crash %target-swift-ide-test -code-completion -code-completion-token=A -source-filename=%s
// REQUIRES: asserts
protocol P
struct A<I:P{var d={enum S<T{case#^A^#
