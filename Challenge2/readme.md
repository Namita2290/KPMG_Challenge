<h2>PROBLEM STATEMENT</h2>

We need to write code that will query the meta data of an instance within AWS and provide a json formatted output. 

<b>I have written this script in powershell using Az and Az.ResourceGraph Module. I have used Managed Service Identity to login to Azure Resource Manager.</b>

        A script to query metadate of an azure virtual machine.
        This script utilizes Az.ResoruceGraph powershell module to query the meatadata of an azure virtual machine of your choice and returns the data in the JSON format.
        It can also print the specific properties metadata of the virtual machine.

    PARAMETERS
        subscriptionId
        resourceGroupName
        Resource group where your machine is deployed.
        hostname Host for which metadata needs to be gathered.
        propertyKey
        Meta data of specific property of the virtual machine.
    
        To get the complete metadata, use 
        explore-metadata.ps1 -subscriptionid "" -resourceGroupName "" -hostname ""

        To get the meta data of a specific property of the VM, use
        explore-metadata.ps1 -subscriptionid "" -resourceGroupName "" -hostname "" -propertyKey ""

