# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command completed with exit code $?."' EXIT

# Variables
rgName=rg-abhi-vm
vmName=vm-abhi-dev
jitNetworkAccessPolicyName=default

# Login to Azure under the context of SP using certificate
spAppId=<SP-Client-Id>
tenantId=<Azure-Tenant-Id>
certificate=abhi-dev-cert.pem
echo "Initiated login to Azure using cert based SP"
az login --service-principal --username $spAppId --tenant $tenantId --password $certificate --verbose
echo "Login successful to Azure subscription.."

# # Get VM & Resource Group Name
# vmName=$(az vm list | jq -r '.[].name')
# echo "Virtual Machine name: " $vmName
# rgName=$(az vm list | jq -r '.[].resourceGroup')
# echo "Resource Group name: " $rgName

# # Get VM running status
# vmStatus=$(az vm list -d | jq -r '.[].powerState')
# if [ "$vmStatus" = "VM running" ]; then
#     echo "VM is already running"
# else
#     # Start Azure VM
#     echo "Starting VM"
#     az vm start -g $rgName -n $vmName --verbose
#     echo "VM started"
# fi

# Get VM running status
vmStatus=$(az vm show -g $rgName -n $vmName --show-details --query "powerState" -o tsv)
if [ "$vmStatus" = "VM running" ]; then
    echo "VM $vmName in Resource Group $rgName is already running.."
else
    # Start Azure VM
    echo "Starting VM"
    az vm start -g $rgName -n $vmName --verbose
    echo "VM $vmName started in Resource Group $rgName.."
fi

# Invoke the below script to request Just-In-Time access to VM
echo "Executing jit-initiate.sh .."
# Use Source command to wait till the execution completes
source jit-initiate.sh $rgName $vmName $jitNetworkAccessPolicyName

# Logout of Azure
echo "Logging out of Azure subscription.."
az logout

# Launch my VM
echo "Launch RDP to the VM.."
mstsc.exe vm-abhi-dev.rdp