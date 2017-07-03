# iSCSIConfiguration
This script configures the iSCSI network adapters, enables iSCSI, installs MPIO, and configures MPIO after a reboot. It utilizes a workflow to reboot the server and finalize the script.

Usage: prep-ISCSI -PSComputerName 10.58.161.33 -VLAN_Name ISCSI -ISCSI_AIP 10.58.17.22 -ISCSI_BIP 10.58.17.23 -PSCredential 10.58.161.33\administrator
