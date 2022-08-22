# Azure automation script to create a Dev VM

This automation script creates resources in the Azure. Used WSL2 with Ubuntu Distro on Windows 11. 
1. [abhi-azure-dev.sh](/src/abhi-azure-dev.sh) - This script creates the following resources
    * Resource group
    * Service principal with a self-signed certificate
    * Self signed certificate downloaded from AKV. The pfx file is deleted after conversion to pem   
    * Key Vault for storing VM password & certificate for Service Principal
    * Virtual Machine (VNet, NIC, IP) with auto shutdown enabled
    ```bash
    # Run this script
    ./abhi-azure-dev.sh <resource-group-name> <location> <user-name> <vm-password> <sp-name>
    ```
2. Just-In-Time (JIT) access to VM - Microsoft Defender for Cloud offers JIT. With JIT, you can lock down the inbound traffic to your VMs, reducing exposure to attacks while providing easy access to connect to VMs when needed. Refer [Just-in-time explained](https://docs.microsoft.com/en-us/azure/defender-for-cloud/just-in-time-access-overview). JIT VM access can be enabled using multiple ways - [JIT access](https://docs.microsoft.com/en-us/azure/defender-for-cloud/just-in-time-access-usage?tabs=jit-config-api%2Cjit-request-api). The method used here is [JIT network access policies using REST API](https://docs.microsoft.com/en-us/rest/api/securitycenter/jit-network-access-policies) in bash script. 
    * [jit-create-update.sh](/src/jit-create-update.sh) - This script creates a policy for protecting resources using Just-in-Time access control. Refer [Jit Network Access Policies - Create Or Update](https://docs.microsoft.com/en-us/rest/api/securitycenter/jit-network-access-policies/create-or-update)
        ```bash
        # Run this script
        ./jit-create-update.sh <resource-group-name> <vm-name>
        ```
    * [jit-initiate.sh](/src/jit-initiate.sh) - This script initiate a JIT access from a specific Just-in-Time policy configuration. The JIT access is requested for 3 hours. Refer [Jit Network Access Policies - Initiate](https://docs.microsoft.com/en-us/rest/api/securitycenter/jit-network-access-policies/initiate)
        ```bash
        # Run this script
        jit-initiate.sh <resource-group-name> <vm-name> <jitNetworkAccessPolicyName>
        ```
3. [rdp-my-msft-vm.vbs](/src/rdp-my-msft-vm.vbs) - This script launches the RDP session on windows system with a double click. Requires rdp file to be downloaded & [StartMyVM.sh](/src/StartMyVM.sh) bash script to be present. The script requires the `Public IP address` of the VM to be updated.
4. [StartMyVM.sh](/src/StartMyVM.sh) - This script launches the VM RDP after login to the Azure subscription via  certificate based authentication using Service Principal. If the VM is switched off it will start it. It also executes the script [jit-initiate.sh](/src/abhi-azure-dev.sh) & requests the JIT access. This in turn adds an inbound NSG rule to allow port 3389. The script requires `SP-Client-Id`, `Azure-Tenant-Id` & the `sp-certificate` downloaded from Key Vault should be placed in the same location.

![alt txt](/images/resource-visualizer.jpg)

![alt txt](/images/resources.jpg)