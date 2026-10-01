import Foundation

/// IPv4 subnet calculator engine.
///
/// Swift port of the Android `IPv4` class (`app/src/main/.../IPv4.kt`),
/// using fixed-width `UInt32` arithmetic so bit operations behave
/// identically on all Apple platforms (Swift's `Int` is 64-bit).
///
/// Usage: `let ip = try IPv4(cidr: "192.168.0.0/16")`
struct IPv4 {
    var baseIPNumeric: UInt32
    var netmaskNumeric: UInt32

    enum Error: Swift.Error, LocalizedError {
        case message(String)
        var errorDescription: String? {
            if case .message(let m) = self { return m }
            return nil
        }
    }

    init(cidr IPinCIDRFormat: String) throws {
        let st = IPinCIDRFormat.split(separator: "/", omittingEmptySubsequences: false)
        guard st.count == 2 else {
            throw Error.message("Invalid CIDR format '\(IPinCIDRFormat)', should be: xx.xx.xx.xx/xx")
        }
        let symbolicIP = String(st[0])
        guard let numericCIDR = Int(st[1]), numericCIDR >= 0, numericCIDR <= 32 else {
            throw Error.message("CIDR must be between 0 and 32")
        }

        let ipParts = symbolicIP.split(separator: ".", omittingEmptySubsequences: false)
        guard ipParts.count == 4 else {
            throw Error.message("Invalid IP address: \(symbolicIP)")
        }

        var base: UInt32 = 0
        var shift = 24
        for part in ipParts {
            guard let value = Int(part), value == (value & 0xff) else {
                throw Error.message("Invalid IP address: \(symbolicIP)")
            }
            base |= UInt32(value) << shift
            shift -= 8
        }
        baseIPNumeric = base

        // NOTE: the Android version computes `-1 shl (32 - cidr)`, but JVM
        // shift distances are masked to 5 bits, so `/0` shifts by 0 and
        // wrongly yields 255.255.255.255. This port implements /0 correctly.
        netmaskNumeric = numericCIDR == 0 ? 0 : UInt32.max << (32 - numericCIDR)
    }

    var prefixLength: Int { netmaskNumeric.nonzeroBitCount }

    var ip: String { IPv4.symbolic(baseIPNumeric) }

    var netmask: String { IPv4.symbolic(netmaskNumeric) }

    var cidr: String { "\(IPv4.symbolic(baseIPNumeric & netmaskNumeric))/\(prefixLength)" }

    func getAvailableIPs(_ numberOfIPs: Int) -> [String] {
        let totalIPs = UInt64(1) << (32 - prefixLength)
        let baseIP = baseIPNumeric & netmaskNumeric
        let limit = min(totalIPs, UInt64(max(numberOfIPs, 0)))
        guard limit > 1 else { return [] }
        return (1..<limit).map { IPv4.symbolic(baseIP &+ UInt32(truncatingIfNeeded: $0)) }
    }

    var hostAddressRange: String {
        let totalIPs = UInt64(1) << (32 - prefixLength)
        let baseIP = UInt64(baseIPNumeric & netmaskNumeric)
        switch totalIPs {
        case 1:
            return IPv4.symbolic(UInt32(truncatingIfNeeded: baseIP))
        case 2:
            let first = IPv4.symbolic(UInt32(truncatingIfNeeded: baseIP))
            let last = IPv4.symbolic(UInt32(truncatingIfNeeded: baseIP + 1))
            return "\(first) - \(last)"
        default:
            let firstIP = IPv4.symbolic(UInt32(truncatingIfNeeded: baseIP + 1))
            let lastIP = IPv4.symbolic(UInt32(truncatingIfNeeded: baseIP + totalIPs - 2))
            return "\(firstIP) - \(lastIP)"
        }
    }

    var numberOfHosts: UInt64 { UInt64(1) << (32 - prefixLength) }

    var wildcardMask: String { IPv4.symbolic(netmaskNumeric ^ UInt32.max) }

    var broadcastAddress: String {
        let totalIPs = UInt64(1) << (32 - prefixLength)
        let baseIP = UInt64(baseIPNumeric & netmaskNumeric)
        return IPv4.symbolic(UInt32(truncatingIfNeeded: baseIP + totalIPs - 1))
    }

    var netmaskInBinary: String { IPv4.binary(netmaskNumeric) }

    var classificationSummary: String {
        let firstOctet = baseIPNumeric >> 24 & 0xff
        let secondOctet = baseIPNumeric >> 16 & 0xff
        switch firstOctet {
        case 127: return "Loopback · Class A"
        case 169 where secondOctet == 254: return "Link-Local · Class B"
        case 10: return "Private (10.0.0.0/8) · Class A"
        case 172 where (16...31).contains(secondOctet): return "Private (172.16.0.0/12) · Class B"
        case 192 where secondOctet == 168: return "Private (192.168.0.0/16) · Class C"
        case 224...239: return "Multicast · Class D"
        case 240...255: return "Reserved · Class E"
        case ..<128: return "Public · Class A"
        case ..<192: return "Public · Class B"
        default: return "Public · Class C"
        }
    }

    func contains(_ IPaddress: String) throws -> Bool {
        let st = IPaddress.split(separator: ".", omittingEmptySubsequences: false)
        guard st.count == 4 else {
            throw Error.message("Invalid IP address: \(IPaddress)")
        }
        var checkingIP: UInt32 = 0
        var shift = 24
        for part in st {
            guard let value = Int(part), value == (value & 0xff) else {
                throw Error.message("Invalid IP address: \(IPaddress)")
            }
            checkingIP |= UInt32(value) << shift
            shift -= 8
        }
        return (baseIPNumeric & netmaskNumeric) == (checkingIP & netmaskNumeric)
    }

    func contains(_ child: IPv4) -> Bool {
        let subnetID = child.baseIPNumeric
        let subnetMask = child.netmaskNumeric
        return (subnetID & self.netmaskNumeric) == (self.baseIPNumeric & self.netmaskNumeric)
            && self.netmaskNumeric < subnetMask
            && self.baseIPNumeric <= subnetID
    }

    func validateIPAddress() -> Bool {
        let address = self.ip
        if address.hasPrefix("0") { return false }
        let pattern = #"\A(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}\z"#
        return address.range(of: pattern, options: .regularExpression) != nil
    }

    private func boundaryAddr(lowBoundary: Bool) -> String {
        let range = hostAddressRange
        let pattern = #"(\d+\.\d+\.\d+\.\d+)\s+\-\s+(\d+\.\d+\.\d+\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let m = regex.firstMatch(in: range, range: NSRange(range.startIndex..., in: range)),
              m.numberOfRanges == 3,
              let r = Range(m.range(at: lowBoundary ? 1 : 2), in: range)
        else { return "" }
        return String(range[r])
    }

    var firstIPAddr: String { boundaryAddr(lowBoundary: true) }

    var lastIPAddr: String { boundaryAddr(lowBoundary: false) }

    // MARK: - Formatting helpers

    private static func symbolic(_ ip: UInt32) -> String {
        "\(ip >> 24 & 0xff).\(ip >> 16 & 0xff).\(ip >> 8 & 0xff).\(ip & 0xff)"
    }

    private static func binary(_ number: UInt32) -> String {
        var result = ""
        var mask: UInt32 = 1
        for i in 1...32 {
            result = (number & mask) != 0 ? "1\(result)" : "0\(result)"
            if i % 8 == 0 && i != 32 { result = ".\(result)" }
            mask <<= 1
        }
        return result
    }
}
