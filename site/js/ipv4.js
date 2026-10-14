/*
 * IPv4 subnet engine.
 *
 * Port of the Android and iOS IPv4 classes. Results match the apps.
 * Math uses unsigned 32-bit values, so /0 gives mask 0.0.0.0.
 */
(function (root) {
    'use strict';

    function toNumeric(octets) {
        return ((octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3]) >>> 0;
    }

    function toSymbolic(value) {
        return [
            (value >>> 24) & 255,
            (value >>> 16) & 255,
            (value >>> 8) & 255,
            value & 255
        ].join('.');
    }

    function maskFor(prefix) {
        return prefix === 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) >>> 0;
    }

    function toBinary(value) {
        var bits = [];
        for (var shift = 24; shift >= 0; shift -= 8) {
            bits.push(((value >>> shift) & 255).toString(2).padStart(8, '0'));
        }
        return bits.join('.');
    }

    function parseOctets(text) {
        var parts = String(text).split('.');
        if (parts.length !== 4) {
            throw new Error('Invalid IP address: ' + text);
        }
        return parts.map(function (part) {
            if (!/^\d{1,3}$/.test(part) || Number(part) > 255) {
                throw new Error('Invalid IP address: ' + text);
            }
            return Number(part);
        });
    }

    function parsePrefix(text) {
        if (!/^\d{1,2}$/.test(String(text)) || Number(text) > 32) {
            throw new Error('CIDR must be between 0 and 32');
        }
        return Number(text);
    }

    /**
     * @param {number[]} octets Four integers from 0 to 255.
     * @param {number} prefix Integer from 0 to 32.
     */
    function IPv4(octets, prefix) {
        this.prefixLength = parsePrefix(prefix);
        this.baseIP = toNumeric(parseOctets(octets.join('.')));
        this.netmaskNumeric = maskFor(this.prefixLength);
    }

    /** Parse a string such as "192.168.1.10/24". */
    IPv4.parse = function (cidr) {
        var parts = String(cidr).split('/');
        if (parts.length !== 2) {
            throw new Error("Invalid CIDR format '" + cidr + "', should be: xx.xx.xx.xx/xx");
        }
        return new IPv4(parseOctets(parts[0]), parts[1]);
    };

    IPv4.prototype.networkNumeric = function () {
        return (this.baseIP & this.netmaskNumeric) >>> 0;
    };

    IPv4.prototype.totalIPs = function () {
        return Math.pow(2, 32 - this.prefixLength);
    };

    IPv4.prototype.address = function () {
        return toSymbolic(this.baseIP);
    };

    IPv4.prototype.networkAddress = function () {
        return toSymbolic(this.networkNumeric());
    };

    IPv4.prototype.cidr = function () {
        return this.networkAddress() + '/' + this.prefixLength;
    };

    IPv4.prototype.netmask = function () {
        return toSymbolic(this.netmaskNumeric);
    };

    IPv4.prototype.wildcardMask = function () {
        return toSymbolic((~this.netmaskNumeric) >>> 0);
    };

    IPv4.prototype.broadcastAddress = function () {
        return toSymbolic((this.networkNumeric() + this.totalIPs() - 1) >>> 0);
    };

    IPv4.prototype.hostCount = function () {
        return this.totalIPs();
    };

    IPv4.prototype.hostRange = function () {
        var network = this.networkNumeric();
        var total = this.totalIPs();
        if (total === 1) {
            return toSymbolic(network);
        }
        if (total === 2) {
            return toSymbolic(network) + ' - ' + toSymbolic(network + 1);
        }
        return toSymbolic(network + 1) + ' - ' + toSymbolic(network + total - 2);
    };

    IPv4.prototype.netmaskBinary = function () {
        return toBinary(this.netmaskNumeric);
    };

    IPv4.prototype.classification = function () {
        var first = (this.baseIP >>> 24) & 255;
        var second = (this.baseIP >>> 16) & 255;
        if (first === 127) return 'Loopback · Class A';
        if (first === 169 && second === 254) return 'Link-Local · Class B';
        if (first === 10) return 'Private (10.0.0.0/8) · Class A';
        if (first === 172 && second >= 16 && second <= 31) return 'Private (172.16.0.0/12) · Class B';
        if (first === 192 && second === 168) return 'Private (192.168.0.0/16) · Class C';
        if (first >= 224 && first <= 239) return 'Multicast · Class D';
        if (first >= 240) return 'Reserved · Class E';
        if (first < 128) return 'Public · Class A';
        if (first < 192) return 'Public · Class B';
        return 'Public · Class C';
    };

    /** Return every result field as an ordered list of label and value pairs. */
    IPv4.prototype.results = function () {
        return [
            { key: 'netmask', label: 'Subnet Mask', value: this.netmask() },
            { key: 'hosts', label: 'Number of Hosts', value: String(this.hostCount()) },
            { key: 'broadcast', label: 'Broadcast Address', value: this.broadcastAddress() },
            { key: 'wildcard', label: 'Wildcard Mask', value: this.wildcardMask() },
            { key: 'range', label: 'Hosts Address Range', value: this.hostRange() },
            { key: 'binary', label: 'Netmask Binary', value: this.netmaskBinary() },
            { key: 'class', label: 'IP Classification', value: this.classification() }
        ];
    };

    if (typeof module !== 'undefined' && module.exports) {
        module.exports = IPv4;
    } else {
        root.IPv4 = IPv4;
    }
})(typeof self !== 'undefined' ? self : this);
