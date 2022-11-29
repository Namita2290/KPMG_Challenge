#Requires -Modules Az.ResourceGraph

param(

    $subscriptionId,
    $resourceGroupName,
    $hostname,
    $propertyKey

)

Function LoginToAz{
try{
    
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
    $instanceData = Search-AzGraph -Query $query -Subscription $subscriptionId -First 100     
    
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

