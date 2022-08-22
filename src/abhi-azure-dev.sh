# To run this script you need to pass the User name & password for the VM
# Example: ./abhi-azure-dev.sh <resource-group-name> <location> <user-name> <vm-password> <sp-name>

# # Get the commandline parameters into variables
# rgName=$1
# location=$2
# userName=$3
# vmPassword=$4
# spName=$5

echo "Enter Resource Group name"
read rgName
echo "Enter Resource Group location"
read location
echo "Enter VM user name"
read userName
echo "Enter VM password"
read vmPassword
echo "Enter Service Principal name"
read spName

# Check of the parameters entered are null or not
if [ -z "$rgName" ] || [ -z "$location" ] || [ -z "$userName" ] || [ -z "$vmPassword" ] || [ -z "$spName" ];
then
    echo "Enter the required parameters"
    exit
fi

# Create resource group for dev VM
# This size is required to support nested virtualization. Refer: https://azure.microsoft.com/en-us/blog/introducing-the-new-dv3-and-ev3-vm-sizes/
# For all VM sizes that support nested virtualization, refer https://docs.microsoft.com/en-us/azure/virtual-machines/acu
size=Standard_D4s_v3

echo "Create resource group for dev VM.."
az group create -n $rgName -l $location --tags "RG-Name=Abhi-VM"

# Create a KeyVault to store the secrets & certificates. Ensure the Key Vault name is unique
kvName=kv-$(date '+%Y-%m-%d-%H-%M-%S')
echo "Create key vault.."
az keyvault create -n $kvName -g $rgName -l $location

# Store VM password as secret in Key Vault. The password is passed as parameter to the script
echo "Store VM password as secret in Key Vault.."
secretName=vm-password
az keyvault secret set --vault-name $kvName --name $secretName --value $vmPassword

# Create a Service Principal with certificate based autentication for Dev RG
# Get the resource group ID for scope
rgId=$(az group show -n $rgName --query id -o tsv)
# Create service principal
certificateName=abhi-dev-cert
echo "Create Service Principal & self-signed certificate. The PEM file contains a correctly formatted PRIVATE KEY and CERTIFICATE.."
echo "The certificate is stored in the Key Vault after creation.."
appId=$(az ad sp create-for-rbac -n $spName \
    --role contributor --scopes $rgId \
    --create-cert \
    --cert $certificateName \
    --keyvault $kvName)

# Retrieve certificate with its private key from Key Vault
echo "Download the certificate along with its private from Key Vault.."
az keyvault secret download --file abhi-dev-cert.pfx --vault-name $kvName --name $certificateName --encoding base64
# Convert the .pfx file into a .pem file
echo "Convert the .pfx file into a .pem file.."
openssl pkcs12 -nodes -in $certificateName.pfx -passin pass: -out $certificateName.pem
# Delete the pfx file as it is not needed anymore
echo "Delete the pfx file as it is not needed anymore.."
rm $certificateName.pfx

# Get the windows image
publisher=MicrosoftWindowsDesktop
offer=Windows-11
sku=win11-21h2-pro
echo "Get the image OS.."
osImage=$(az vm image list --publisher $publisher --offer $offer --sku $sku --all --query "[0].urn" -o tsv)
# Create VM. Pass the parameters when running the shell script
# Parameters required: admin-username & admin-password
vmName=vm-abhi-dev
echo "Create VM using the OS image.."
az vm create \
    --resource-group $rgName --name $vmName \
    --image $osImage --size $size --location $location \
    --admin-username $userName --admin-password $vmPassword \
    --tags Identifier=VM-Dev \
    --public-ip-address-allocation static --public-ip-sku Standard \
    --verbose

# Enable auto shutdown every night at 9:pm EST hours
echo "Enable auto shutdown every night at 9:pm EST hours.."
az vm auto-shutdown -g $rgName -n $vmName --time 0100

# # Create resource group for dev projects
# rgName=rg-abhi-dev
# location=canadacentral
# echo "Create resource group for dev projects.."
# az group create -n $rgName -l $location --tags "RG-Name=Abhi-dev"

# # Assign owner role to the resource group
# # Get the resource group ID for scope
# rgId=$(az group show -n $rgName --query id -o tsv)
# echo "Assign the owner role to the Service Principal on the resource group for Dev Projects.."
# az role assignment create --assignee $appId --role "Owner" --scope $rgId