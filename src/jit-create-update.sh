rgName=rg-abhi-vm
vmName=vm-abhi-dev
VMID=$(az vm show -g $rgName -n $vmName -o tsv --query "id")
ascLocation=$(az vm show -g $rgName -n $vmName -o tsv --query "location")
SUB=$(echo $VMID | cut -d \/ -f 3)
ENDPOINT="https://management.azure.com/subscriptions/$SUB/resourceGroups/$rgName/providers/Microsoft.Security/locations/$ascLocation/jitNetworkAccessPolicies/default?api-version=2020-01-01"
POLICY_ID="/subscriptions/$SUB/resourceGroups/$rgName/providers/Microsoft.Security/locations/eastus/jitNetworkAccessPolicies/default"
JSON=$(cat <<-EOF
  {
    "kind": "Basic",
    "properties": {
       "virtualMachines": [
          {
            "id": "$VMID",
            "ports": [
              {
                "number": "22",
                "protocol": "*",
                "allowedSourceAddressPrefix": "*",
                "maxRequestAccessDuration": "PT3H"
              },
              {
                "number": "3389",
                "protocol": "*",
                "allowedSourceAddressPrefix": "*",
                "maxRequestAccessDuration": "PT3H"
              }
            ]
          }
        ]
    },
    "id": "$POLICY_ID",
    "name": "default",
    "type": "Microsoft.Security/locations/jitNetworkAccessPolicies",
    "location": "$ascLocation"
  }
EOF
)
COMPRESSED_JSON=$(echo $JSON | jq -c)
az rest --verbose --method put --uri "$ENDPOINT" --body "$COMPRESSED_JSON" -o json 2> response-create-update-jit