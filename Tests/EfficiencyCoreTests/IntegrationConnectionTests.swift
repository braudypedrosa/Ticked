import XCTest
@testable import EfficiencyCore

final class IntegrationConnectionTests: XCTestCase {
    func testConnectionsGroupByProviderAndCountActiveAccounts() {
        let basecampOne = IntegrationConnection.fixture(provider: .basecamp, accountLabel: "Client One", status: .active)
        let basecampTwo = IntegrationConnection.fixture(provider: .basecamp, accountLabel: "Client Two", status: .needsReauth)
        let linear = IntegrationConnection.fixture(provider: .linear, accountLabel: "Product", status: .active)

        let grouped = IntegrationConnection.groupedByProvider([basecampOne, basecampTwo, linear])

        XCTAssertEqual(grouped[.basecamp]?.map(\.accountLabel), ["Client One", "Client Two"])
        XCTAssertEqual(grouped[.linear]?.map(\.accountLabel), ["Product"])
        XCTAssertEqual(IntegrationConnection.activeCount(in: [basecampOne, basecampTwo, linear]), 2)
    }
}
