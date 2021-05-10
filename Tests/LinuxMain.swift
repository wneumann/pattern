import XCTest

import patternTests

var tests = [XCTestCaseEntry]()
tests += patternTests.allTests()
XCTMain(tests)
