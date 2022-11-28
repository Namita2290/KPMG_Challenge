#Requires -Modules Az.ResourceGraph

<#
    
    .SYNOPSIS
        A script to query metadate of an azure virtual machine.

    .DESCRIPTION
        This script utilizes Az.ResoruceGraph powershell module to query the meatadata of an azure virtual machine of your choice and returns the data in the JSON format.
        It can also print the specific properties metadata of the virtual machine.

    .PARAMETER subscriptionId
        Id of the Subscription where resource is deployed.

    .PARAMETER resourceGroupName
        Resource group where your machine is deployed.

    .PARAMETER hostname
        Host for which metadata needs to be gathered.
    
    .PARAMETER propertyKey
        Meta data of specific property of the virtual machine.

    .INPUTS
        NA

    .OUTPUTS
        JSON Metadata of the virtual machine.

    .EXAMPLE
        To get the complete metadata, use 
        explore-metadata.ps1 -subscriptionid "434535-3534534-cxxx-xxxxxxx" -resourceGroupName "demo_rg" -hostname "demo_vm"

        To get the meta data of a specific property of the VM, use
        explore-metadata.ps1 -subscriptionid "434535-3534534-cxxx-xxxxxxx" -resourceGroupName "demo_rg" -hostname "demo_vm" -propertyKey "osProfile"

#>

param(

    $subscriptionId,
    $resourceGroupName,
    $hostname,
    $propertyKey

)

#region Functions

Function LoginToAz{
try{
    
    #using managed service identity to login to azure
    Connect-AzAccount -Identity | Out-Null

}catch{
    
    $errorLogin = "Error While logging in to azure - $($error[0])"
    AddtoLogfile $errorLogin 85
}

}

Function GetMetaData{
param()
try{
    
    Write-Host "Runnign query..."
    $instanceData = Search-AzGraph -Query $query -Subscription $subscriptionId -First 1000     
    
    if($instanceData){
        
        Write-Host "Data has been fetched successfully."
    }
    else{
        
        Write-host "Unable to fetch the data or data is missing!"
    }

    if($propertyKey){
        
        Write-Host "Property Key is provided, hence printing only the required data."
        $jsonMeta = ($instanceData | Where-Object{($_.name -eq $hostname) -and ($_.resourceGroup -eq $resourceGroupName)}).Properties.$propertyKey | ConvertTo-Json -Depth 100

    }else{
        
        Write-Host "Propert key is not provided, hence printing the complete metadata."
        $jsonMeta = $instanceData | Where-Object{($_.name -eq $hostname) -and ($_.resourceGroup -eq $resourceGroupName)} | ConvertTo-Json -Depth 100 
    }
    Start-Sleep 10
    Write-Host $jsonMeta


}catch{
    
    $errorMeta = "Error while fetching meta data for the instance $hostname - $($error[0])"
    Write-Host $errorMeta
}

}

#endregion

#region Variables
$query = "Resources| where type == 'microsoft.compute/virtualmachines'"

#endregion

#region Main
try{

Write-Host "Connecting to Azure Resource Manager using Managed Service Identity"
LoginToAz

Write-Host "Setting Context to the subscription Id provided."
Set-AzContext -Subscription $subscriptionId | Out-Null

Write-Host "Fetching Metadata"
GetMetaData

}catch{
    
    $errorMain = "Error in the region Main - $($error[0])"
    Write-Host $errorMain
}
#endregion