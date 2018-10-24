
<#
.SYNOPSIS

This script will create ESXi installer ISOs for automated installing of ESXi  
.DESCRIPTION

The goal of this script is to help in the deployment of ESXi in an automated manor that doesn't require DHCP. 
This script will take an Excel file that lists the specified Hosts and their network configuration and a source ESXi ISO which are then used to created 
named ESXi ISOs for every host that needs ESXi installed on them. Each of the generated ISOs has a KS file and a replaced BOOT.CFG file that will auto 
run the KS file that is specified. These ISOs can be mounted to each host individually, or in the case of UCS Manager, a KVM policy can be put in place, 
to auto mount every Service Profile to the specific ISO that matches the Service Profile Name. 
This allows for rapid, automated deployment of ESXi without the need of DHCP. 

There is a manual step to this process that isn't automated yet, please see the readme.md in the github repo. 

ImportExcel Module is required for this script. https://github.com/dfinke/ImportExcel
The linux iso cmdline tools growisofs is also required and is packaged in the repo. 


.PARAMETER ImportFile
The Excel file to be imported

.PARAMETER ISO
The ISO file to use as the source for the script. 

.EXAMPLE
 .\Build-ESXiInstallISO.ps1 -ImportFile .\vSphereDesign.xlsx -ISO ESXi.6.7

#>

##############################################
#region Parameters
##############################################

Param(

    [Parameter(Position = 0,
        Mandatory = $true,
        HelpMessage = 'The config file to use')]
    [ValidateNotNullOrEmpty()]	
    [string]$ImportFile,

    [Parameter(Position = 1,
        Mandatory = $true,
        HelpMessage = 'The ISO to use')]
    [ValidateNotNullOrEmpty()]		
    [string]$ISO	
)

#endregion

##############################################
#region Script
##############################################
#Requires –Modules ImportExcel

#import the Excel file
$Sheets = Get-ExcelSheetInfo -Path $ImportFile

#read every sheet into a hash table
foreach ($Sheet in $Sheets) {
    New-Variable -Name ("VMData" + $($Sheet.name)) -Value (Import-Excel -Path $ImportFile -WorkSheetname $($Sheet.name))
}

#process through each host in the sheet. 
foreach ($vmhost in $VMDataHosts) {

    #removes any leftover KS.KS files
    $ExistingKSFile = "Files\KS.KS"
    if (Test-Path $ExistingKSFile) {
        Remove-Item $ExistingKSFile
    }

    #checks if there is a management vlan configured in the design
    if ($vmhost.ESXiMgmtVlan) {

        $NetworkInfo = "network --bootproto=static --device=vmnic0 --nameserver=" + $vmhost.DNS + " --netmask=" + $vmhost.ESXiMgmtSubnet + " --gateway=" + $vmhost.ESXiMgmtGateway + " --vlanid=" + $vmhost.ESXiMgmtVlan + " --addvmportgroup=0 --ip=" + $vmhost.ESXiMgmtIP + " --hostname=" + $vmhost.Hostname + "`n" 
    }
    else {

        $NetworkInfo = "network --bootproto=static --device=vmnic0 --nameserver=" + $vmhost.DNS + " --netmask=" + $vmhost.ESXiMgmtSubnet + " --gateway=" + $vmhost.ESXiMgmtGateway + " --addvmportgroup=0 --ip=" + $vmhost.ESXiMgmtIP + " --hostname=" + $vmhost.Hostname + "`n" 
    }

    #top of the KS file. Using Linux line endings
    $FileContents = "# Auto install `n" +
    "# Accept the VMware End User License Agreement`n" +
    "vmaccepteula`n" +
    "# Set the root password for the DCUI and Tech Support Mode`n" +
    "rootpw " + $vmhost.RootPassword + "`n" + 
    "# The install media is in the CD-ROM drive`n" +
    "install --firstdisk --overwritevmfs`n" + 
    $NetworkInfo +
    "reboot"
    
    #export the file contents to the KS file
    $FileContents | Out-File -FilePath Files\KS.CFG -Encoding utf8 -Force

    #copies the source ISO to the current dir
    Copy-Item $ISO -Destination "$($vmhost.Hostname).iso"
    
    #manual sleep process. This is for the growisofs, as I encountered race issues if I called it too quickly. 
    Start-Sleep -Seconds 4

    #Adds the contents of the Files dir, to the ISO. This will overwrite any files. 
    .\growisofs.exe -M "$($vmhost.Hostname).iso" -R -J  .\Files
    
    #manual sleep process. This is for the growisofs, as I encountered race issues if I called it too quickly.
    Start-Sleep -Seconds 4

}

##############################################
#endregion
##############################################
#end of script