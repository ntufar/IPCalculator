package com.tufar.IPCalculator

import kotlin.math.pow

class IPv4(IPinCIDRFormat: String) {

    var baseIPnumeric: Int
    var netmaskNumeric: Int

    init {
        val st = IPinCIDRFormat.split("/")
        if (st.size != 2)
            throw NumberFormatException("Invalid CIDR format '$IPinCIDRFormat', should be: xx.xx.xx.xx/xx")
        val symbolicIP = st[0]
        val numericCIDR = st[1].toInt()
        if (numericCIDR > 32)
            throw NumberFormatException("CIDR can not be greater than 32")

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

        if (numericCIDR < 8)
            throw NumberFormatException("Netmask CIDR can not be less than 8")
        netmaskNumeric = -1
        netmaskNumeric = netmaskNumeric shl (32 - numericCIDR)
    }

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
        get() {
            val i = (0..31).first { (netmaskNumeric shl it) == 0 }
            return "${convertNumericIpToSymbolic(baseIPnumeric and netmaskNumeric)}/$i"
        }

    fun getAvailableIPs(numberofIPs: Int): List<String> {
        val result = mutableListOf<String>()
        val numberOfBits = (0..31).first { (netmaskNumeric shl it) == 0 }
        var numberOfIPs = 0
        for (n in 0 until (32 - numberOfBits)) {
            numberOfIPs = numberOfIPs shl 1
            numberOfIPs = numberOfIPs or 0x01
        }
        val baseIP = baseIPnumeric and netmaskNumeric
        for (i in 1 until numberOfIPs.coerceAtMost(numberofIPs)) {
            result.add(convertNumericIpToSymbolic(baseIP + i))
        }
        return result
    }

    val hostAddressRange: String
        get() {
            val numberOfBits = (0..31).first { (netmaskNumeric shl it) == 0 }
            var numberOfIPs = 0
            for (n in 0 until (32 - numberOfBits)) {
                numberOfIPs = numberOfIPs shl 1
                numberOfIPs = numberOfIPs or 0x01
            }
            val baseIP = baseIPnumeric and netmaskNumeric
            val firstIP = convertNumericIpToSymbolic(baseIP + 1)
            val lastIP = convertNumericIpToSymbolic(baseIP + numberOfIPs - 1)
            return "$firstIP - $lastIP"
        }

    val numberOfHosts: Long
        get() {
            val numberOfBits = (0..31).first { (netmaskNumeric shl it) == 0 }
            return 2.0.pow(32 - numberOfBits).toLong()
        }

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
            if (netmaskNumeric == -1) return "0.0.0.0"
            val numberOfBits = (0..31).first { (netmaskNumeric shl it) == 0 }
            var numberOfIPs = 0
            for (n in 0 until (32 - numberOfBits)) {
                numberOfIPs = numberOfIPs shl 1
                numberOfIPs = numberOfIPs or 0x01
            }
            val baseIP = baseIPnumeric and netmaskNumeric
            return convertNumericIpToSymbolic(baseIP + numberOfIPs)
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
