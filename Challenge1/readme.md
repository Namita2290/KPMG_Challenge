<h2>PROBLEM STATEMENT</h2>

A 3-tier environment is a common setup. Use a tool of your choosing/familiarity create these resources.

This architecture consists of three tiers i.e. web, app and data tier. Each tier has its own load balancer, subnet, virtual machines deployed in a scale set and network security group.

I have created three modules for each tier in the solution using terraform and they are being invoked using main.tf inside Three_Tier_arch directory.


Directory Structure:

1. <b>outputs.tf</b>: Returns ip address of public facing load balancer.
2. <b>resources.tf</b>: config. file to create required resources.
3. <b>variables.tf</b>: file containing variables required for this module.

Web Tier Summary:

1. A web tier subnet is created for virtual machines in the scale set.
2. An NSG dedicated to this subnet will be created to allow web traffic from Internet and through the external external load balancers to virtual machines.
3. <b>You can also add a rule to allow SSH or RDP from an allowed source IP address, such as a “jump box” virtual machine in subnet.</b>

Following rules will be applied in the web tier NSG:

1. Port 80 from * to 10.0.1.0/24
2. Port 443 from * to 10.0.1.0/24
3. Allow Load Balancer Probe
4. Deny * from Virtual Network

If web traffic comes in through the external load balancer then it will be allowed by one of those rules. We are creating a specific rule to allow probe traffic from the external load balancer; this is because the last rule will deny all other traffic from the virtual network. We don’t want any other traffic in the virtual network getting into these virtual machines.

<h3>App Tier Terraform Module</h3>

Directory Structure:

1. <b>resources.tf</b>: config. file to create required resources.
2. <b>variables.tf</b>: file containing variables required for this module.

App Tier Summary:

1. We can keep application servers inside app tier subnet as scale set. 
2. A dedicated NSG will allow traffic from web tier to business tier.

Following rules will be applied in the app tier NSG:

1. Allow port 80 from 10.0.1.0/24 to 10.0.2.0/24
2. Allow all traffic from Azure Load Balancer
3. Block all traffic from virtual network
4. Allow Load Balancer probe

All traffic from web tier to app tier is allowed on port 80.

<h3>Data Tier Terraform Module</h3>

Directory Structure:

1. <b>resources.tf</b>: config. file to create required resources.
2. <b>variables.tf</b>: file containing variables required for this module.

Data Tier Summary:

1. We deploy our database servers with a scale set inside the data tier subnet.
2. Another dedicated NSG will be deployed to allow traffic from business to data tier.

Only the application servers in the app tier should be allowed to connect to the databases. <b>You can also allow database administration from restricted & trusted sources</b>.

Following trafficc will be allowed in the data tier NSG:

1. Allow 1433 from 10.0.2.0/24 to 10.0.3.0/24
2. Allow all traffic from load balancer
3. Bloack all traffic from virtual network

<h3>Deploy Three Tier Architecture</h3>

Directory Structure:

1. <b>main.tf</b>: Used to invoke all the three modules.
2. <b>terraform.tfvars</b>: Used to provide inputs to the modules.
3. <b>outputs.tf</b>: Used to print ip address of public load balancerload balancer.
4. <b>providers.tf</b>: Used to provide authentication and subscription to azure resource manager.
5. <b>terraform.tf</b>: Used to provide required providers information and terraform version
6. <b>variables.tf</b>: Stores information fo variables required for the successful execution.

