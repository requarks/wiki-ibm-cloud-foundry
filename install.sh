#!/bin/bash

echo "============================="
echo "OS Environment Check"
echo "============================="

echo "-> Check root in Docker container, non-root users are 1000 and above"
id -u
whoami

echo "-> Check OS is Ubuntu"
cat /etc/os-release | grep "PRETTY_NAME"

echo "-> Check dpkg is installed"
dpkg --version | grep "dpkg"

echo "-> Check curl is installed"
curl -V | grep "curl"

echo "-> Check wget is installed"
wget --version | grep "GNU Wget"


#echo "============================="
#echo "Pre-requisite OS Packages"
#echo "============================="
# IBM Cloud Delivery Pipelines are permitted sudo to apt-get and dpkg
# Documented here, but this is held under .bluemix folder
# See documentation: https://cloud.ibm.com/docs/services/ContinuousDelivery?topic=ContinuousDelivery-deliverypipeline_about#deliverypipeline_jobs
#echo "-> Installing necessary OS Packages"
#sudo apt-get --assume-yes install -y yarn g++ make python curl git openssh gnupg


echo "============================="
echo "Wiki.js - binaries download via Bash"
echo "============================="

echo "-> Creating Directory Structure"
mkdir -p wiki
mkdir -p logs
#chown -R node:node ./wiki ./logs

echo "-> Fetching latest Wiki.js version..."
WIKIJS_LATEST_VERSION=$(
curl -s https://api.github.com/repos/Requarks/wiki/releases/latest \
| grep "tag_name" \
| cut -d ":" -f 2,3 \
| tr -d \" \
| tr -d , \
| tr -d " " \
)
echo "Wiki.js version is $WIKIJS_LATEST_VERSION"

echo "-> Fetching latest Wiki.js version build release..."
# Use cURL follow re-direct and retain re-direct filename
# Leveraging the lessons learnt from Gist here - https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8

# DO NOT USE auto-generated GitHub tarball_url or zipball_url, which is a snapshot of the GitHub repository sourec code at time of Release
# Instead use the Release's published/packaged "assets" using browser_download_url, and removing the url for the Windows release
WIKIJS_LATEST_DL_URL=$(curl -s https://api.github.com/repos/Requarks/wiki/releases/latest \
| grep "browser_download_url.*" \
| grep -v ".*windows.*" \
| cut -d ":" -f 2,3 \
| tr -d \" \
| tr -d , \
| tr -d " " \
)

curl -s -O -J -L $WIKIJS_LATEST_DL_URL

WIKIJS_LATEST_DL_FILE=$(find . -type f -iname '*wiki*.tar.gz' -print)

tar xzf $WIKIJS_LATEST_DL_FILE -C ./wiki

rm $WIKIJS_LATEST_DL_FILE

echo "Downloaded file is $WIKIJS_LATEST_DL_FILE from $WIKIJS_LATEST_DL_URL"
echo "Extracted to $PWD/wiki"
echo "Removed file $WIKIJS_LATEST_DL_FILE"

# tar on macOS would not work with above, as this requires filename after operators

function pandoc_install()
{
echo "-> Fetching latest Pandoc version..."
PANDOC_LATEST_VERSION=$(
curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
| grep "tag_name" \
| cut -d ":" -f 2,3 \
| tr -d \" \
| tr -d , \
| tr -d " " \
)
echo "Pandoc version is $PANDOC_LATEST_VERSION"

echo "-> Fetching latest Pandoc version build release..."
# Use cURL follow re-direct and retain re-direct filename
# Leveraging the lessons learnt from Gist here - https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8

# DO NOT USE auto-generated GitHub tarball_url or zipball_url, which is a snapshot of the GitHub repository sourec code at time of Release
# Instead use the Release's published/packaged "assets" using browser_download_url, and removing the url for the Windows release
PANDOC_LATEST_DL_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest \
| grep "browser_download_url.*" \
| grep ".*.deb.*" \
| cut -d ":" -f 2,3 \
| tr -d \" \
| tr -d , \
| tr -d " " \
)

curl -s -O -J -L $PANDOC_LATEST_DL_URL
PANDOC_LATEST_DL_FILE=$(find . -type f -iname '*pandoc*.deb' -print)
echo "Downloaded file is $PANDOC_LATEST_DL_FILE from $PANDOC_LATEST_DL_URL"

echo "Installing Pandoc..."
#sudo dpkg -i $PANDOC_LATEST_DL_FILE
dpkg -i $PANDOC_LATEST_DL_FILE

echo "Removing Pandoc .deb file"
rm $PANDOC_LATEST_DL_FILE
echo "---"

echo "For Pandoc PDF output, install LaTeX distribution TeX Live"
#sudo apt-get --assume-yes install texlive
apt-get --assume-yes install texlive
}

# Described here for re-use by others as a standalone install script,
# but this is executed by IBM Cloud Continuous Delivery pipeline where sudo privileges are available for dpkg
#pandoc_install


echo "============================="
echo "Wiki.js - prepare CF App for deployment to IBM Cloud Foundry public"
echo "============================="

# Automatically generate and echo new env varaiables from the Cloud Foundry Public System-Provided Environment Variables for a CF Service Instance on IBM Cloud
export cf_auto_env_db_service_cred_user=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].credentials.connection.postgres.authentication.username' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_db_service_cred_password=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].credentials.connection.postgres.authentication.password' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_db_service_database_schema=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].credentials.connection.postgres.database' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_db_service_host=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].credentials.connection.postgres.hosts[].hostname' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_db_service_port=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].credentials.connection.postgres.hosts[].port')
export cf_auto_env_db_service_name=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].instance_name' | sed -e 's/^\"//' -e 's/\"$//')
#export cf_auto_env_db_service_name=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].name' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_db_service_product_label=$(echo $VCAP_SERVICES | jq '."databases-for-postgresql"[].label' | sed -e 's/^\"//' -e 's/\"$//')

# Automatically generate and echo new env varaiables from the Cloud Foundry Public System-Provided Environment Variables for the Deployed CF Application on IBM Cloud
export cf_auto_env_app_id=$(echo $VCAP_APPLICATION | jq '.application_id' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_app_name=$(echo $VCAP_APPLICATION | jq '.application_name' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_app_uris=$(echo $VCAP_APPLICATION | jq '.application_uris[]' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_api=$(echo $VCAP_APPLICATION | jq '.cf_api' | sed -e 's/^\"//' -e 's/\"$//')
export cf_auto_env_region=$(echo $VCAP_APPLICATION | jq '.application_uris[]' | sed -e 's/^\"//' -e 's/\"$//' | sed -e 's/^wikijs-cf\.//' -e 's/\.cf\..*//' | head -n 1)
export cf_auto_env_org_space_name=$(echo $VCAP_APPLICATION | jq '.space_name' | sed -e 's/^\"//' -e 's/\"$//')

# Workaround because wiki/config.yml does not accept Envrionment Variables, therefore inject into the config.yml with sed
sed -i "0,/RE/s/  host:/  host: $cf_auto_env_db_service_host/" ./wiki/config.yml
sed -i "0,/RE/s/  port:/  port: $cf_auto_env_db_service_port/" ./wiki/config.yml
sed -i "0,/RE/s/  user:/  user: $cf_auto_env_db_service_cred_user/" ./wiki/config.yml
sed -i "0,/RE/s/  pass:/  pass: $cf_auto_env_db_service_cred_password/" ./wiki/config.yml
sed -i "0,/RE/s/  db:/  db: $cf_auto_env_db_service_database_schema/" ./wiki/config.yml


# Workaround if choose not to use provided node_modules folder from Wiki.js Release package
# NOTE: If execute npm install without removing provided node_modules, errors will occur such as "404 Not Found - GET https://registry.npmjs.org/elasticsearch6 - Not found"
echo "-> Replacing node_modules; deletion then npm install"
rm -rf ./wiki/node_modules
cd wiki
npm install

echo "============================="
echo "Completed downloading and preparing CF App of Wiki.js version $WIKIJS_LATEST_VERSION, beginning npm start (i.e. node server)"
echo ""
cf_url1=$(echo $cf_auto_env_app_uris | awk '{print $1}')
cf_url2=$(echo $cf_auto_env_app_uris | awk '{print $2}')
echo "Starting on URLs:"
echo "https://$cf_url1"
echo "https://$cf_url2"

echo "============================="



DEBUGGING="FALSE"
if [ "$DEBUGGING" = "TRUE" ]; then
  echo "============================="
  echo "DEBUGGING"
  echo "============================="
  echo "---"
  echo "-> DEBUGGING - echo custom generated Environment Variables from the Cloud Foundry Public System-Provided Environment Variables"
  env | grep "cf_auto_env_.*" | sort
  echo "----"
  echo "-> DEBUGGING - echo standard Cloud Foundry Public System-Provided Environment Variables for CF Container System Variables on IBM Cloud"
  env | grep "BLUEMIX.*"
  env | grep "^BUILD_DIR="
  env | grep "^CACHE_DIR="
  env | grep "CF_.*" | sort
  env | grep "^HOME="
  env | grep "INIT_.*"
  env | grep "MEMORY_.*"
  env | grep "^PATH="
  env | grep "^PORT="
  env | grep "^PWD="
  echo "----"

  echo "-> DEBUGGING - Home Directory"
  echo "Directory Contents of $PWD"
  ls -lha

  echo "-> DEBUGGING - Extracted Wiki.js Directory"
  echo "Directory Contents of $PWD"
  ls -lha ./$PWD/wiki
fi
