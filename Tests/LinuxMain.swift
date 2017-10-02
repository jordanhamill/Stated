// import XCTest
// @testable import StatedTests

// XCTMain([
//     testCase(StatedTests.allTests),
// ])


import XCTest
@testable import SimpleStatedTests
@testable import InputArgsAndMappedStateTests

XCTMain([
    testCase(SimpleStatedTests.allTests),
    testCase(InputArgsAndMappedStateTests.allTests)
])