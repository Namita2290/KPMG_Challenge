param(
$customObject = [ordered]@{
    
    "a" = [ordered]@{
            "b" = [ordered]@{
                    "c" = "d"
                  }
          }
},
$inputkey = "b"
)

#region Functions

Function NestedObject{
param(
    $inputObject,
    $inputKey
)
try{
    
    if($inputObject."$inputKey" -eq $null){
        
        if($inputObject[0]."$inputKey" -eq $null){
            
            if(($inputObject[0])[0]."$inputKey" -eq $null){
                
                Write-Host "Required key not found in the object."
            }
            else{
                
                ($inputObject[0])[0]."$inputKey" | ConvertTo-Json -Depth 10
                
            }

        }
        else{
            
            $inputObject[0]."$inputKey" |ConvertTo-Json -Depth 10 

        }
    }
    else{
        
        $inputObject."$inputKey" | ConvertTo-Json -Depth 10
    }

}catch{

    Write-Host "Error in the function - $($Error[0])"
}

}

#endregion

#region Main
NestedObject -inputObject $customObject -inputKey $inputkey
#endregion