
<#

Title: RemoteiSCSIConfig.ps1
Date: 06/27/2017
Author: Bradford Perkins
Description: This script configures the iSCSI network adapters, enables iSCSI, installs MPIO, and configures MPIO after a reboot. It utilizes a workflow to reboot the server and finalize the script.

Usage: prep-ISCSI -PSComputerName 10.58.161.33 -VLAN_Name ISCSI -ISCSI_AIP 10.58.17.22 -ISCSI_BIP 10.58.17.23 -PSCredential 10.58.161.33\administrator

Ideas: I could probably nest within another workflow and run on as many servers as I want with the foreach -parallel {} activity. 
#>

#Creates the workflow to configure iSCSI
workflow prep-ISCSI {
    #Create parameters
    param ([string[]]$VLAN_Name,

           [string[]]$ISCSI_AIP,

           [string[]]$ISCSI_BIP)      
    
    #Name the iSCSI adapters and configure default subnet mask
    $VLAN_A = "$($VLAN_Name)_A"
    $VLAN_B = "$($VLAN_Name)_B"
    $ISCSI_Mask = 24

    #Rename Network Adapters to designate iSCSI A and B interfaces
    Get-NetAdapter -Name "Ethernet 2" | Rename-NetAdapter -NewName $VLAN_A
    Get-NetAdapter -Name "Ethernet 3" | Rename-NetAdapter -NewName $VLAN_B

    #Set IP address on ISCSI_A adapter
    $VLAN_AAdapter = Get-NetAdapter -Name $VLAN_A
    New-NetIPAddress `
        -InterfaceAlias $VLAN_AAdapter.Name `
        -AddressFamily IPv4 `
        -IPAddress $ISCSI_AIP `
        -PrefixLength $ISCSI_Mask

    #Set IP address on ISCSI_B adapter
    $VLAN_BAdapter = Get-NetAdapter -Name $VLAN_B
    New-NetIPAddress `
        -InterfaceAlias $VLAN_BAdapter.Name `
        -AddressFamily IPv4 `
        -IPAddress $ISCSI_BIP `
        -PrefixLength $ISCSI_Mask

    #Enable iSCSI and Configure to Start Automatically, Set-Service is required when running the command remotely
    Set-Service msiscsi -Status Running
    Set-Service msiscsi -startuptype "automatic"

    #Enable and configure MPIO
    Enable-WindowsOptionalFeature -Online -FeatureName MultipathIO
    Enable-MSDSMAutomaticClaim -BusType iSCSI
 
    #Reboot computer and continue configuration of MPIO
    Restart-Computer -Wait -Force -For WinRM
    #Change default load balancing policy to Least Queue Depth
    Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy LQD
    Set-MPIOSetting -NewDiskTimeout 60
     
}