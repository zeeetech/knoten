import Foundation
import Testing

@testable import KnotenCore

@Test func thenPassesTheValueAlong() async {
    let result = await KnotenResult<Int>.success(1).then { value in
        .success(value + 1)
    }
    #expect(result.value == 2)
}

@Test func thenPropagatesTheFirstFailure() async {
    let result = await KnotenResult<Int>.failure(.notFound).then { _ in
        KnotenResult<String>.success("never reached")
    }
    #expect(result.error == .notFound)
}

@Test func decodeReportsMalformedJSON() {
    let result = JSONDecoder().decode(EmptyResponse.self, from: Data("not json".utf8), label: "thing")
    #expect(result.error == .invalidResponse("thing"))
}
