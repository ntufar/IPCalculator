// Run with: node --test tests/web/
const test = require('node:test');
const assert = require('node:assert/strict');
const IPv4 = require('../../site/js/ipv4.js');

test('/16 network matches the iOS engine tests', () => {
    const ip = IPv4.parse('192.168.0.0/16');
    assert.equal(ip.netmask(), '255.255.0.0');
    assert.equal(ip.broadcastAddress(), '192.168.255.255');
    assert.equal(ip.wildcardMask(), '0.0.255.255');
    assert.equal(ip.hostCount(), 65536);
    assert.equal(ip.hostRange(), '192.168.0.1 - 192.168.255.254');
    assert.equal(ip.netmaskBinary(), '11111111.11111111.00000000.00000000');
    assert.equal(ip.classification(), 'Private (192.168.0.0/16) · Class C');
});

test('host address is reduced to the network in the CIDR string', () => {
    const ip = IPv4.parse('192.168.1.10/24');
    assert.equal(ip.address(), '192.168.1.10');
    assert.equal(ip.cidr(), '192.168.1.0/24');
    assert.equal(ip.networkAddress(), '192.168.1.0');
    assert.equal(ip.broadcastAddress(), '192.168.1.255');
    assert.equal(ip.hostRange(), '192.168.1.1 - 192.168.1.254');
    assert.equal(ip.hostCount(), 256);
});

test('/31 has two addresses and a range of both', () => {
    const ip = IPv4.parse('192.168.1.0/31');
    assert.equal(ip.hostRange(), '192.168.1.0 - 192.168.1.1');
    assert.equal(ip.hostCount(), 2);
});

test('/32 has one address', () => {
    const ip = IPv4.parse('10.0.0.5/32');
    assert.equal(ip.hostRange(), '10.0.0.5');
    assert.equal(ip.broadcastAddress(), '10.0.0.5');
    assert.equal(ip.netmask(), '255.255.255.255');
});

test('/0 gives a zero mask, not 255.255.255.255', () => {
    const ip = IPv4.parse('10.0.0.1/0');
    assert.equal(ip.netmask(), '0.0.0.0');
    assert.equal(ip.wildcardMask(), '255.255.255.255');
    assert.equal(ip.broadcastAddress(), '255.255.255.255');
    assert.equal(ip.hostCount(), 4294967296);
    assert.equal(ip.cidr(), '0.0.0.0/0');
});

test('address space above 127.x is handled as unsigned', () => {
    const ip = IPv4.parse('200.1.2.3/8');
    assert.equal(ip.netmask(), '255.0.0.0');
    assert.equal(ip.broadcastAddress(), '200.255.255.255');
    assert.equal(ip.classification(), 'Public · Class C');
});

test('classification covers the special ranges', () => {
    assert.equal(IPv4.parse('127.0.0.1/8').classification(), 'Loopback · Class A');
    assert.equal(IPv4.parse('169.254.1.1/16').classification(), 'Link-Local · Class B');
    assert.equal(IPv4.parse('10.1.1.1/8').classification(), 'Private (10.0.0.0/8) · Class A');
    assert.equal(IPv4.parse('172.20.1.1/16').classification(), 'Private (172.16.0.0/12) · Class B');
    assert.equal(IPv4.parse('172.32.1.1/16').classification(), 'Public · Class B');
    assert.equal(IPv4.parse('224.0.0.1/4').classification(), 'Multicast · Class D');
    assert.equal(IPv4.parse('240.0.0.1/4').classification(), 'Reserved · Class E');
    assert.equal(IPv4.parse('8.8.8.8/8').classification(), 'Public · Class A');
});

test('results() lists every field in display order', () => {
    const keys = IPv4.parse('192.168.1.1/24').results().map((row) => row.key);
    assert.deepEqual(keys, [
        'netmask', 'hosts', 'broadcast', 'wildcard',
        'range', 'binary', 'class'
    ]);
});

test('invalid input is rejected', () => {
    const bad = [
        '192.168.1.1',
        '192.168.1.1/33',
        '192.168.1.1/-1',
        '192.168.1.256/24',
        '192.168.1/24',
        '192.168.1.1.1/24',
        '192.168.1.a/24',
        '192.168.1.1/',
        '/24',
        ''
    ];
    for (const value of bad) {
        assert.throws(() => IPv4.parse(value), undefined, value);
    }
});
