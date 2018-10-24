##ESXi Full Auto Scripted Install Readme

### What it is

Automation ESXi deployments without DHCP is a pain to say the least. The only way I know how to do it, without DHCP, 
is to use a unique KS file per ISO with the static IPs, and hostnames defined. This script will create a KS file per host
and then load that KS file onto a ISO just for that host. This does result in having a ISO per host that is being installed.
These ISOs can be mounted to each host individually, or in the case of UCS Manager, a KVM policy can be put in place, 
to auto mount every Service Profile to the specific ISO that matches the Service Profile Name, which allows for 
fully automated ESXi installations without any interaction! 

Note: There is a setup task that has to be done manually. I haven't figured out a way to make this work on Windows, 
without some extra apps installed, like 7-zip. 


### Process

This script will take an Excel file that lists the specified Hosts and their network configuration and a source ESXi ISO which are then used to created 
named ESXi ISOs for every host that needs ESXi installed on them. Each of the generated ISOs has a KS file and a replaced BOOT.CFG file that will auto 
run the KS file that is specified. 
This allows for rapid, automated deployment of ESXi without the need of DHCP. 

### Setup

There is a manual step to this process that isn't automated yet which is modifying the source ISO's BOOT.CFG file to specify to run the KS file. 
Every ESXi ISO has a unique BOOT.CFG file, as this file specifies the modules to be loaded, which change with every ESXi version, and the specific vendor
edition of ESXi that is going to be installed. 

For this step, open up your source ISO and copy the BOOT.CFG file to the Files directory. 
change this line kernelopt= to 
kernelopt=ks=cdrom:/KS.CFG 
and save the file

The manual setup is done now and the script can be run. 

Note: failing to do this step, will result in ESXi not installing at all or having issues. A sample BOOT.CFG is included in the files dir, but always use your own. 

### acknowledgments
Thanks to William Lang and his post [Virtually Ghetto](http://www.virtuallyghetto.com/2011/05/semi-interactive-automated-esxi.html) and a bunch of others that 
helped me write this script and figure out this process on Windows. 

