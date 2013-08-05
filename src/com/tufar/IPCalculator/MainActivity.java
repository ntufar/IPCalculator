package com.tufar.IPCalculator;

import com.tufar.IPCalculator.R;


import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.widget.NumberPicker;
import android.widget.NumberPicker.OnScrollListener;
import android.widget.TextView;

public class MainActivity extends Activity {
	NumberPicker ip1;
	NumberPicker ip2;
	NumberPicker ip3;
	NumberPicker ip4;
	NumberPicker netmask_one_number;
	TextView subnetMaskExpanded;
	TextView numberOfHosts;
	TextView broadcastAddress;
	TextView wildcardMask;
	TextView hostsAddressRange;
	TextView netmaskBinary;
	
	IPv4 ipv4 = new IPv4("10.1.0.25/16");
	
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        subnetMaskExpanded = (TextView)findViewById(R.id.subnetMaskExpanded);
        numberOfHosts = (TextView)findViewById(R.id.numberOfHosts);
        broadcastAddress = (TextView)findViewById(R.id.broadcastAddress);
        wildcardMask = (TextView)findViewById(R.id.wildcardMask);
        hostsAddressRange = (TextView)findViewById(R.id.hostsAddressRange);
        netmaskBinary = (TextView)findViewById(R.id.netmaskBinary);
        
        ip1 = (NumberPicker)findViewById(R.id.ip1);
        ip1.setMinValue(0);
        ip1.setMaxValue(255);
        ip1.setValue(192);
        ip1.setOnScrollListener(updateTheResults);
        ip1.setDescendantFocusability(NumberPicker.FOCUS_BLOCK_DESCENDANTS);

        ip2 = (NumberPicker)findViewById(R.id.ip2);
        ip2.setMinValue(0);
        ip2.setMaxValue(255);
        ip2.setValue(168);
        ip2.setOnScrollListener(updateTheResults);
        ip2.setDescendantFocusability(NumberPicker.FOCUS_BLOCK_DESCENDANTS);

        ip3 = (NumberPicker)findViewById(R.id.ip3);
        ip3.setMinValue(0);
        ip3.setMaxValue(255);
        ip3.setValue(0);
        ip3.setOnScrollListener(updateTheResults);
        ip3.setDescendantFocusability(NumberPicker.FOCUS_BLOCK_DESCENDANTS);

        ip4 = (NumberPicker)findViewById(R.id.ip4);
        ip4.setMinValue(0);
        ip4.setMaxValue(255);
        ip4.setValue(0);
        ip4.setOnScrollListener(updateTheResults);
        ip4.setDescendantFocusability(NumberPicker.FOCUS_BLOCK_DESCENDANTS);

        netmask_one_number = (NumberPicker)findViewById(R.id.netmask_one_number);
        netmask_one_number.setMinValue(8);
        netmask_one_number.setMaxValue(31);
        netmask_one_number.setValue(16);
        netmask_one_number.setOnScrollListener(updateTheResults);
        netmask_one_number.setDescendantFocusability(NumberPicker.FOCUS_BLOCK_DESCENDANTS);
    }
    
    OnScrollListener updateTheResults = new OnScrollListener() {
		@Override
		public void onScrollStateChange(NumberPicker view, int scrollState) {
			Integer ip1i = ip1.getValue();
			Integer ip2i = ip2.getValue();
			Integer ip3i = ip3.getValue();
			Integer ip4i = ip4.getValue();
			Integer netmask_one_number_i = netmask_one_number.getValue();
			
			String CIDR = 	ip1i.toString()+"."+
							ip2i.toString()+"."+
							ip3i.toString()+"."+
							ip4i.toString()+"/"+
							netmask_one_number_i.toString();
			try{
				ipv4 = new IPv4(CIDR);
				subnetMaskExpanded.setText(ipv4.getNetmask());
				numberOfHosts.setText(ipv4.getNumberOfHosts().toString());
				broadcastAddress.setText(ipv4.getBroadcastAddress());
				wildcardMask.setText(ipv4.getWildcardMask());
				hostsAddressRange.setText(ipv4.getHostAddressRange());
				netmaskBinary.setText(ipv4.getNetmaskInBinary());
			}catch(Exception e){
				subnetMaskExpanded.setText(e.getMessage());
			}
		}
	};
    
    


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    
}
