# The below variables are to be passed from the calling script
# rgName=rg-abhi-vm
# vmName=vm-abhi-dev
# jitNetworkAccessPolicyName=default

rgName=$1
vmName=$2
jitNetworkAccessPolicyName=$3

VMID=$(az vm show -g $rgName -n $vmName -o tsv --query "id")
ascLocation=$(az vm show -g $rgName -n $vmName -o tsv --query "location")
SUB=$(echo $VMID | cut -d \/ -f 3)
ENDPOINT="https://management.azure.com/subscriptions/$SUB/resourceGroups/$rgName/providers/Microsoft.Security/locations/$ascLocation/jitNetworkAccessPolicies/$jitNetworkAccessPolicyName/initiate?api-version=2020-01-01"
JSON=$(cat <<-EOF
  {
    "virtualMachines": [
      {
        "id": "/subscriptions/$SUB/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName",
        "ports": [
          {
            "number": 3389,
            "duration": "PT3H"
          }
        ]
      }
    ]
  }
EOF
)
COMPRESSED_JSON=$(echo $JSON | jq -c)
echo "Rquest Just-In-Time access for the VM for 3 hours.."
# az rest --verbose --method POST --uri "$ENDPOINT" --body "$COMPRESSED_JSON" -o json 2> response-intiate-jit
az rest --verbose --method POST --uri "$ENDPOINT" --body "$COMPRESSED_JSON" -o json
