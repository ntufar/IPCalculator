import XCTest
@testable import IPCalculator

/// Engine parity with Android `IPv4` for the values shown in the UI.
final class EngineTests: XCTestCase {

    func testDefaultNetwork() throws {
        let ip = try IPv4(cidr: "192.168.0.0/16")
        XCTAssertEqual(ip.netmask, "255.255.0.0")
        XCTAssertEqual(ip.broadcastAddress, "192.168.255.255")
        XCTAssertEqual(ip.wildcardMask, "0.0.255.255")
        XCTAssertEqual(ip.numberOfHosts, 65536)
        XCTAssertEqual(ip.hostAddressRange, "192.168.0.1 - 192.168.255.254")
        XCTAssertEqual(ip.netmaskInBinary, "11111111.11111111.00000000.00000000")
        XCTAssertEqual(ip.classificationSummary, "Private (192.168.0.0/16) · Class C")
    }

    func testEdgePrefixes() throws {
        let ip31 = try IPv4(cidr: "192.168.1.0/31")
        XCTAssertEqual(ip31.hostAddressRange, "192.168.1.0 - 192.168.1.1")
        let ip32 = try IPv4(cidr: "10.0.0.5/32")
        XCTAssertEqual(ip32.hostAddressRange, "10.0.0.5")
        XCTAssertEqual(ip32.broadcastAddress, "10.0.0.5")
    }

    func testZeroPrefix() throws {
        // Correct here: Android's JVM shift masking wrongly gives 255.255.255.255.
        let ip0 = try IPv4(cidr: "0.0.0.0/0")
        XCTAssertEqual(ip0.netmask, "0.0.0.0")
        XCTAssertEqual(ip0.broadcastAddress, "255.255.255.255")
        XCTAssertEqual(ip0.numberOfHosts, 4294967296)
    }

    func testInvalidInputThrows() {
        for bad in ["nope", "1.2.3.4", "1.2.3.4/33", "1.2.3.256/24", "1.2.3/24"] {
            XCTAssertThrowsError(try IPv4(cidr: bad), bad)
        }
    }
}
