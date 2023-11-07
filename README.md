# Udacity-project1-Azure
## Goal
After doing this project, you are able to use the terraform and packer to provision the infrastructure on Azure
## Dependencies:
- An Azure account
- The latest version of [Terraform](#https://developer.hashicorp.com/terraform/downloads) installation
- The latest version of [Packer](#https://developer.hashicorp.com/packer/downloads) installation
- The latest version of [Azure cli](#https://learn.microsoft.com/en-us/cli/azure/)
## Getting started
1. Clone this repo
- With Windows:
> git clone https://github.com/ndhoang123/Udacity-project1-Azure.git
- With Linux:
> git clone git@github.com:ndhoang123/Udacity-project1-Azure.git

2. Install all dependencies that I listed above
3. Export the below necessary value and save on the text editor:
- [Subscription ID](#https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id)
- Application ID, secret key, tenant_ID:
> az ad sp create-for-rbac --role Contributor --scopes /subscriptions/<YourSubcriptionID> --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"

## Guideline
In order to work with cli, you need to log in on the Azure first
> Az login
### Azure policy
1. Go to the policy folder
> cd Policy
2. Deploy a Policy
> AZ policy definition creates --name tagging-policy --display-name "deny-creation-if-untagged-resources" --description "This policy ensures all indexed resources in your subscription have tags and deny deployment if they do not" --rules "policy.json" --mode All
<img width="1037" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/05c437a9-28c9-4135-938a-6212baac634f">

3. Create the Policy Assignment
> az policy assignment create --name 'tagging-policy' --display-name "deny-creation-if-untagged-resources" --policy tagging-policy
<img width="982" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/c6bbfa57-18cb-41de-810e-a6ca3872cd57">

4. List the policy assignments to verify
> az policy assignment list
<img width="1045" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/de495424-3939-4fc0-ba9f-ae2aae4ae882">

5. Go back to the root folder
> cd ..

### Packer
1. Go to the Packer folder
> cd Packer

2. Fill out those variables on server.json that you got the value above:
<img width="921" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/f699ac31-223f-4957-8356-086e69fd771d">

3. Create image
> packer build server.json

4. View images
> az image list
<img width="1044" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/485b9fd7-fcc4-443e-a7f6-a7b7ca01a3ca">

5. Go back to the root folder
> cd ..

### Terraform
1. Go to the Infra folder
> cd Infra
2. Initializing Working Directories
> terraform init
3. Create infrastructure plan
> terraform plan -out solution.plan
4. Deploy the infrastructure plan
> terraform apply "solution.plan"
<img width="1058" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/01c0dbe6-3a9d-47e1-a6c5-7ca2b9c0393b">
<img width="1036" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/bc88083f-20e4-4d82-8e60-7f71b8cb82f4">

5. The output on Azure
<img width="1277" alt="image" src="https://github.com/ndhoang123/Udacity-project1-Azure/assets/27766520/f20b797a-d6bb-419f-b47b-93a8d72eef3d">

After seeing the successful creation on Azure, you need to delete the terraform infra as well as the created image that was done on the Packer section

6. Destroy terraform
> terraform destroy

7. Delete images
> az image delete -g `<Resource-group>` -n `<Your-image-used-on-terraform>`
