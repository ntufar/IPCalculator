package com.tufar.IPCalculator

class IPv4(IPinCIDRFormat: String) {

    var baseIPnumeric: Int
    var netmaskNumeric: Int

    init {
        val st = IPinCIDRFormat.split("/")
        if (st.size != 2)
            throw NumberFormatException("Invalid CIDR format '$IPinCIDRFormat', should be: xx.xx.xx.xx/xx")
        val symbolicIP = st[0]
        val numericCIDR = st[1].toInt()
        if (numericCIDR < 0 || numericCIDR > 32)
            throw NumberFormatException("CIDR must be between 0 and 32")

        val ipParts = symbolicIP.split(".")
        if (ipParts.size != 4)
            throw NumberFormatException("Invalid IP address: $symbolicIP")

        var i = 24
        baseIPnumeric = 0
        for (n in 0..3) {
            val value = ipParts[n].toInt()
            require(value == value and 0xff) { "Invalid IP address: $symbolicIP" }
            baseIPnumeric += value shl i
            i -= 8
        }

        netmaskNumeric = -1
        netmaskNumeric = netmaskNumeric shl (32 - numericCIDR)
    }

    val prefixLength: Int
        get() = Integer.bitCount(netmaskNumeric)

    val ip: String
        get() = convertNumericIpToSymbolic(baseIPnumeric)

    private fun convertNumericIpToSymbolic(ip: Int): String {
        val sb = StringBuilder(15)
        for (shift in 24 downTo 8 step 8) {
            sb.append(ip ushr shift and 0xff)
            sb.append('.')
        }
        sb.append(ip and 0xff)
        return sb.toString()
    }

    val netmask: String
        get() {
            val sb = StringBuilder(15)
            for (shift in 24 downTo 8 step 8) {
                sb.append(netmaskNumeric ushr shift and 0xff)
                sb.append('.')
            }
            sb.append(netmaskNumeric and 0xff)
            return sb.toString()
        }

    val cidr: String
        get() = "${convertNumericIpToSymbolic(baseIPnumeric and netmaskNumeric)}/$prefixLength"

    fun getAvailableIPs(numberofIPs: Int): List<String> {
        val result = mutableListOf<String>()
        val numberOfBits = prefixLength
        val totalIPs = 1L shl (32 - numberOfBits)
        val baseIP = baseIPnumeric and netmaskNumeric
        val limit = minOf(totalIPs, numberofIPs.toLong())
        for (i in 1 until limit) {
            result.add(convertNumericIpToSymbolic((baseIP.toLong() + i).toInt()))
        }
        return result
    }

    val hostAddressRange: String
        get() {
            val totalIPs = 1L shl (32 - prefixLength)
            val baseIP = baseIPnumeric and netmaskNumeric
            return when {
                totalIPs == 1L -> convertNumericIpToSymbolic(baseIP)
                totalIPs == 2L -> {
                    val first = convertNumericIpToSymbolic(baseIP)
                    val last = convertNumericIpToSymbolic((baseIP.toLong() + 1).toInt())
                    "$first - $last"
                }
                else -> {
                    val firstIP = convertNumericIpToSymbolic((baseIP.toLong() + 1).toInt())
                    val lastIP = convertNumericIpToSymbolic((baseIP.toLong() + totalIPs - 2).toInt())
                    "$firstIP - $lastIP"
                }
            }
        }

    val numberOfHosts: Long
        get() = 1L shl (32 - prefixLength)

    val wildcardMask: String
        get() {
            val wcMask = netmaskNumeric xor -1
            val sb = StringBuilder(15)
            for (shift in 24 downTo 8 step 8) {
                sb.append(wcMask ushr shift and 0xff)
                sb.append('.')
            }
            sb.append(wcMask and 0xff)
            return sb.toString()
        }

    val broadcastAddress: String
        get() {
            val totalIPs = 1L shl (32 - prefixLength)
            val baseIP = baseIPnumeric and netmaskNumeric
            return convertNumericIpToSymbolic((baseIP.toLong() + totalIPs - 1).toInt())
        }

    val netmaskInBinary: String
        get() = getBinary(netmaskNumeric)

    private fun getBinary(number: Int): String {
        var result = ""
        var ourMaskBitPattern = 1
        for (i in 1..32) {
            result = if ((number and ourMaskBitPattern) != 0) {
                "1$result"
            } else {
                "0$result"
            }
            if (i % 8 == 0 && i != 0 && i != 32)
                result = ".$result"
            ourMaskBitPattern = ourMaskBitPattern shl 1
        }
        return result
    }

    val classificationSummary: String
        get() {
            val firstOctet = baseIPnumeric ushr 24 and 0xff
            val secondOctet = baseIPnumeric ushr 16 and 0xff
            return when {
                firstOctet == 127 -> "Loopback · Class A"
                firstOctet == 169 && secondOctet == 254 -> "Link-Local · Class B"
                firstOctet == 10 -> "Private (10.0.0.0/8) · Class A"
                firstOctet == 172 && secondOctet in 16..31 -> "Private (172.16.0.0/12) · Class B"
                firstOctet == 192 && secondOctet == 168 -> "Private (192.168.0.0/16) · Class C"
                firstOctet in 224..239 -> "Multicast · Class D"
                firstOctet in 240..255 -> "Reserved · Class E"
                firstOctet < 128 -> "Public · Class A"
                firstOctet < 192 -> "Public · Class B"
                else -> "Public · Class C"
            }
        }

    fun contains(IPaddress: String): Boolean {
        var checkingIP = 0
        val st = IPaddress.split(".")
        if (st.size != 4)
            throw NumberFormatException("Invalid IP address: $IPaddress")
        var i = 24
        for (n in 0..3) {
            val value = st[n].toInt()
            require(value == value and 0xff) { "Invalid IP address: $IPaddress" }
            checkingIP += value shl i
            i -= 8
        }
        return (baseIPnumeric and netmaskNumeric) == (checkingIP and netmaskNumeric)
    }

    fun contains(child: IPv4): Boolean {
        val subnetID = child.baseIPnumeric
        val subnetMask = child.netmaskNumeric
        return (subnetID and this.netmaskNumeric) == (this.baseIPnumeric and this.netmaskNumeric)
                && this.netmaskNumeric < subnetMask
                && this.baseIPnumeric <= subnetID
    }

    fun validateIPAddress(): Boolean {
        val ip = this.ip
        if (ip.startsWith("0")) return false
        return ip.matches(Regex("\\A(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)(\\.(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)){3}\\z"))
    }

    private fun getBoundaryAddr(lowBoundary: Boolean): String {
        val range = hostAddressRange
        val rangeRegex = Regex("(\\d+\\.\\d+\\.\\d+\\.\\d+)\\s+\\-\\s+(\\d+\\.\\d+\\.\\d+\\.\\d+)")
        val m = rangeRegex.find(range)
        return if (m != null) {
            if (lowBoundary) m.groupValues[1] else m.groupValues[2]
        } else ""
    }

    val firstIPAddr: String
        get() = getBoundaryAddr(true)

    val lastIPAddr: String
        get() = getBoundaryAddr(false)
}
