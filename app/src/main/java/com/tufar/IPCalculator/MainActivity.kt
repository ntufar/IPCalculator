package com.tufar.IPCalculator

import android.os.Bundle
import android.widget.NumberPicker
import androidx.appcompat.app.AppCompatActivity
import com.tufar.IPCalculator.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private var ipv4 = IPv4("192.168.0.0/16")

    private val onValueChange = NumberPicker.OnValueChangeListener { _, _, _ ->
        calculateIp()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupNumberPicker(binding.ip1, 0, 255, 192)
        setupNumberPicker(binding.ip2, 0, 255, 168)
        setupNumberPicker(binding.ip3, 0, 255, 0)
        setupNumberPicker(binding.ip4, 0, 255, 0)
        setupNumberPicker(binding.netmaskOneNumber, 8, 31, 16)

        calculateIp()
    }

    private fun setupNumberPicker(picker: NumberPicker, min: Int, max: Int, value: Int) {
        picker.minValue = min
        picker.maxValue = max
        picker.value = value
        picker.setOnValueChangedListener(onValueChange)
        picker.descendantFocusability = NumberPicker.FOCUS_BLOCK_DESCENDANTS
    }

    private fun calculateIp() {
        val cidr = "${binding.ip1.value}.${binding.ip2.value}.${binding.ip3.value}.${binding.ip4.value}/${binding.netmaskOneNumber.value}"
        binding.networkDisplay.text = cidr
        try {
            ipv4 = IPv4(cidr)
            binding.subnetMaskExpanded.text = ipv4.netmask
            binding.numberOfHosts.text = ipv4.numberOfHosts.toString()
            binding.broadcastAddress.text = ipv4.broadcastAddress
            binding.wildcardMask.text = ipv4.wildcardMask
            binding.hostsAddressRange.text = ipv4.hostAddressRange
            binding.netmaskBinary.text = ipv4.netmaskInBinary
        } catch (e: Exception) {
            binding.subnetMaskExpanded.text = e.message
        }
    }
}
