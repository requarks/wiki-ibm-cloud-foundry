# Open Toolchain Structure

- toolchain.yml defines all the tool integrations used in the toolchain; it is executed first and refers to:
  - deploy.json (Defines parameters used in toolchain setup / Page Layout)
  - locals.yml (Translation files)
    - nls/messages.yml (Text Translations)
  - pipeline.yml (Defines the pipeline execution steps)


# IBM Cloud Continuous Delivery import deployment template

## Steps to customising the Deploy page:

1. Under messages.yml, add descriptors (e.g. `deploy.apiKeyTitle: "IBM Cloud API key"`)
1. Under deploy.json, add new property (e.g. under "properties" add `"api-key"` object referencing the description of this property to the key `"deploy.apiKeyTitle"` in messages.yml)
1. Under deploy.json, update the required object to contain new property `"api-key"`
1. Under deploy.json, add new form object (e.g. under "form" add the `"key": "api-key"` and reference to messages.yml again)
1. Under toolchain.yml, add new Environment Variable (e.g. under "env" add `IBM_CLOUD_API_KEY: '{{form.pipeline.parameters.api-key}}'`)
1. Under pipeline.yml, add a new property and reference the environment variable using `${IBM_CLOUD_API_KEY}`
1. In pipeline.yml script section, reference `$IBM_CLOUD_API_KEY` where required


## Execution of Open Toolchain from a public GitHub.com repository

https://cloud.ibm.com/devops/setup/deploy?repository=GITHUB_URL_HERE&env_id=ibm:yp:us-south


## Execution of Open Toolchain from a private git repository

This requires passing a Personal Access Token (PAT) for the first load:

```
https://cloud.ibm.com/devops/setup/deploy?repository=https://<GIT_PAT_HERE>@<GIT_URL_HERE>

Optional inclusion of &branch=<GIT_BRANCH_HERE>
Optional inclusion of &env_id=ibm:yp:<REGION>
```

N.B. be sure to remove the https when pasting the Git URL


## Execution of Open Toolchain on dedicated IBM Cloud, from a private git repository

This requires adding a new URL prefix, and passing a Personal Access Token (PAT) on the first  load:

```
https://console.<IBM_CLOUD_FOUNDRY_DEDICATED_URL_HERE>/devops/setup/deploy?repository=https://<GIT_PAT_HERE>@<GIT_URL_HERE>

Optional inclusion of &branch=<GIT_BRANCH_HERE>
Optional inclusion of &env_id=ibm:yp:<REGION>

```


## Debug of Open Toolchain deployment to IBM Cloud
To Debug Toolchain YML Template errors, add `&nocreate` query parameter to end of the URL.

```
nocreate: Loading the page with nocreate in the query will disable the Create button. Instead of creating the toolchain, the page will log the POST body to the browser's JavaScript console. this parameter is useful for debugging.
```
