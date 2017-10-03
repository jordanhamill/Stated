import XCTest
@testable import StatedTests

XCTMain([
    testCase(SimpleStatedTests.allTests),
    testCase(InputArgsAndMappedStateTests.allTests)
])