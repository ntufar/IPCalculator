package com.tufar.IPCalculator

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.NumberPicker
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
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
        setupNumberPicker(binding.netmaskOneNumber, 0, 32, 16)

        setupCopyListeners()
        calculateIp()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.main, menu)
        updateMenuTitle(menu.findItem(R.id.action_toggle_dark_mode))
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_toggle_dark_mode -> {
                toggleDarkMode()
                updateMenuTitle(item)
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun updateMenuTitle(item: MenuItem) {
        val isDark = getSharedPreferences("prefs", Context.MODE_PRIVATE)
            .getBoolean("dark_mode", false)
        item.title = if (isDark) getString(R.string.action_light_mode)
        else getString(R.string.action_dark_mode)
    }

    private fun toggleDarkMode() {
        val prefs = getSharedPreferences("prefs", Context.MODE_PRIVATE)
        val isDark = prefs.getBoolean("dark_mode", false)
        prefs.edit().putBoolean("dark_mode", !isDark).apply()
        AppCompatDelegate.setDefaultNightMode(
            if (isDark) AppCompatDelegate.MODE_NIGHT_NO
            else AppCompatDelegate.MODE_NIGHT_YES
        )
    }

    private fun setupNumberPicker(picker: NumberPicker, min: Int, max: Int, value: Int) {
        picker.minValue = min
        picker.maxValue = max
        picker.value = value
        picker.setOnValueChangedListener(onValueChange)
        picker.descendantFocusability = NumberPicker.FOCUS_BLOCK_DESCENDANTS
    }

    private fun setupCopyListeners() {
        binding.cardSubnetMask.setOnClickListener {
            copyToClipboard("Subnet Mask", binding.subnetMaskExpanded.text.toString())
        }
        binding.cardNumberOfHosts.setOnClickListener {
            copyToClipboard("Number of Hosts", binding.numberOfHosts.text.toString())
        }
        binding.cardBroadcast.setOnClickListener {
            copyToClipboard("Broadcast Address", binding.broadcastAddress.text.toString())
        }
        binding.cardWildcard.setOnClickListener {
            copyToClipboard("Wildcard Mask", binding.wildcardMask.text.toString())
        }
        binding.cardHostRange.setOnClickListener {
            copyToClipboard("Hosts Address Range", binding.hostsAddressRange.text.toString())
        }
        binding.cardNetmaskBinary.setOnClickListener {
            copyToClipboard("Netmask Binary", binding.netmaskBinary.text.toString())
        }
        binding.cardIpClassification.setOnClickListener {
            copyToClipboard("IP Classification", binding.ipClassification.text.toString())
        }
    }

    private fun copyToClipboard(label: String, text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText(label, text)
        clipboard.setPrimaryClip(clip)
        Toast.makeText(this, getString(R.string.copied_to_clipboard), Toast.LENGTH_SHORT).show()
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
            binding.ipClassification.text = ipv4.classificationSummary
        } catch (e: Exception) {
            binding.subnetMaskExpanded.text = e.message
        }
    }
}
