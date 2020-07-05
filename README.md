# IBM Cloud Foundry public - Wiki.js deployment

This repo is an Open Toolchain definition for IBM Cloud Continuous Delivery, to deploy Wiki.js to IBM Cloud Foundry public.

This deployment assumes you have an [IBM Cloud account](https://cloud.ibm.com/registration).

For information about Wiki.js, including detailed installation steps, read the following links:

- [Official Website](https://wiki.js.org/)
- [Installation Guide](https://wiki.js.org/get-started)
- [GitHub Repository](https://github.com/Requarks/wiki)


## Automated deployment via IBM Cloud Continuous Delivery

<a href="https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/Requarks/wiki-ibm-cloud-foundry" rel="Deploy to IBM Cloud Foundry public"><img src="https://cloud.ibm.com/devops/setup/deploy/button.svg" alt="Deploy to IBM Cloud Foundry" width="250"/></a>

### Step-by-step guidance if required:
1. Click Deploy to IBM Cloud, this imports the Open Toolchain deployment template into IBM Cloud Continuous Delivery.
1. Open Toolchain is imported and is complete when the page loads
    - toolchain.yml is executed first and refers to:
      - deploy.json (Page Layout)
      - locals.yml (Translation files)
      - nls/messages.yml (Text Translations)
      - pipeline.yml (Execution steps)
1. Select the GitHub repository to clone to, and Cloud Foundry deployment target.
1. Click "Create" to execute the toolchain, including the build pipeline and IBM Cloud Foundry public
1. Build pipeline is executed
    - Download the latest Wiki.js release
    - Unpack the latest Wiki.js release
    - Create IBM Cloud services for Cloud Foundry app (i.e. PostgreSQL)
    - Populate Cloud Foundry manifest.yml Environment Variables with Env Var from Open Toolchain input
    - Blue-Green Deploy to Cloud Foundry (i.e. `cf push`)
1. Wiki.js is running on IBM Cloud Foundry public


# Manual deployment from IBM Cloud CLI
1. Login to IBM Cloud
> `ibmcloud login`
1. Target the Resource Group
>`ibmcloud target -g resource_group`
1. Create new IBM Cloud Foundry public Organization for the RG into a specified Region (edit as required)
>`ibmcloud account org-create new-cf-org --region us-south`
1. Create new IBM Cloud Foundry public Space in the CF Org for the RG
> `ibmcloud cf create-space new-cf-space -o new-cf-org`
1. Target the new CF Org and CF Space, and set the domain to be used in connecting to Cloud Foundry. NOTE: Using `ibmcloud target --cf` will revert to your default domain which may not be preferred for this deployment
> `ibmcloud target --cf-api api.us-south.cf.cloud.ibm.com -o new-cf-org -s new-cf-space`
1. Create new PostgreSQL service named "db-psql" (edit name as required) in the Resource Group with default basic/low settings
> `ibmcloud resource service-instance-create db-psql databases-for-postgresql standard us-south`
1. Check the new PostgreSQL service named "db-psql" (edit name as required) is active (takes 5-15mins for production-ready PostgreSQL DB)
> `ibmcloud resource service-instances`
1. Create service instance alias named "db-psql" for the PostgreSQL service named "db-psql" to be used for binding the to CF App running in the CF Space
> `ibmcloud resource service-alias-create db-psql --instance-name db-psql`
1. Edit manifest-vars.yml file as required to change deployment names
> Specify the Region and PostgreSQL database service instance name
1. Instantiate the CF App using cf push
> `ibmcloud cf push --vars-file=manifest-vars.yml`
1. NOTE: In the unlikely event there is an issue with the routing for the CF App after deployment, attempt below (source: https://cloud.ibm.com/docs/cloud-foundry-public?topic=cloud-foundry-public-update-domain)
> `ibmcloud cf map-route wikijs-cf us-south.cf.appdomain.cloud --hostname wikijs-cf`


---

**NOTES:**
- IBM Cloud Resource Groups cannot be deleted
- Within an IBM Cloud Resource Group, Cloud Foundry Orgs cannot be deleted
- System Domains used for CF Apps are associated to the Account's default region (e.g accounts from EU would use eu-de.cf.appdomain.cloud, and accounts from US would use us-south.cf.appdomain.cloud)
- Use the IBM Cloud CLI to list all IBM Cloud Foundry public marketplace services to attach to CF Apps with `$ ibmcloud cf marketplace | awk -F'   ' '{print $1}'`
