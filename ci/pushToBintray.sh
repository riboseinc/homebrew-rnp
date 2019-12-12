#!/bin/bash

API=https://api.bintray.com

# BINTRAY_USER=$1
# BINTRAY_API_KEY=$2
# BINTRAY_REPO=$3
# BINTRAY_PACKAGE=$4
# BOTTLE_VERSION
BOTTLE="${BOTTLE_LOCAL_FILENAME}"

echostatus() {
  echo "$@" 1>&2;
}

main() {
  CURL="curl -u${BINTRAY_USER}:${BINTRAY_API_KEY} -H Content-Type:application/json -H Accept:application/json"
  if (check_package_exists); then
    echostatus "The package ${BINTRAY_PACKAGE} does not exit. It will be created"
    create_package
  fi

  deploy_bottle
}

check_package_exists() {
  echostatus "Checking if package ${BINTRAY_PACKAGE} exists..."
  package_exists=`[ $(${CURL} --write-out %{http_code} --silent --output /dev/null -X GET  ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}/${BINTRAY_PACKAGE})  -eq 200 ]`
  echostatus "Package ${BINTRAY_PACKAGE} exists? y:1/N:0 ${package_exists}"
  return ${package_exists}
}

create_package() {
  echostatus "Creating package ${BINTRAY_PACKAGE}..."
  if [ -f "${BINTRAY_DESCRIPTOR_FILENAME}" ]; then
    data="@${BINTRAY_DESCRIPTOR_FILENAME}"
  else
    data="{
    \"name\": \"${BINTRAY_PACKAGE}\",
    \"desc\": \"auto\",
    \"desc_url\": \"auto\",
    \"labels\": [\"bash\", \"example\"]
    }"
  fi

  ${CURL} -X POST -d "${data}" ${API}/packages/${BINTRAY_USER}/${BINTRAY_REPO}
}

deploy_bottle() {
  if (upload_content); then
    echostatus "Publishing ${BOTTLE}..."
    ${CURL} -X POST ${API}/content/${BINTRAY_USER}/${BINTRAY_REPO}/${BINTRAY_PACKAGE}/${BOTTLE_VERSION}/publish -d "{ \"discard\": \"false\" }"
  else
    echostatus "[SEVERE] First you should upload your bottle ${BOTTLE}"
  fi
}

upload_content() {
  echostatus "Uploading ${BOTTLE}..."
  uploaded=` [ $(${CURL} --write-out %{http_code} --silent --output /dev/null -T ${BOTTLE} -H X-Bintray-Package:${BINTRAY_PACKAGE} -H X-Bintray-Version:${BOTTLE_VERSION} ${API}/content/${BINTRAY_USER}/${BINTRAY_REPO}/${BOTTLE}) -eq 201 ] `
  echostatus "BOTTLE ${BOTTLE} uploaded? y:1/N:0 ${uploaded}"
  return ${uploaded}
}

main "$@"
