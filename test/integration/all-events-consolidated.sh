#!/usr/bin/env bash

set -o errexit

STACK_PREFIX="$1"
TARGET_AEM_STACK_PREFIX="$2"

CONFIG_PATH=examples/user-config/

AEM_PACKAGE_GROUP=shinesolutions
AEM_PACKAGE_NAME=aem-helloworld-content
AEM_PACKAGE_VERSION=0.0.1
AEM_PACKAGE_URL="http://central.maven.org/maven2/com/$AEM_PACKAGE_GROUP/$AEM_PACKAGE_NAME/$AEM_PACKAGE_VERSION/$AEM_PACKAGE_NAME-$AEM_PACKAGE_VERSION.zip"
AEM_EXPORT_PACKAGE_DATE=$(date "+%Y%m%d")

##################################################
# Check AEM Consolidated Architecture readiness
##################################################

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Unschedule jobs for live-snapshot
##################################################

make unschedule-live-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Unschedule jobs for offline-snapshot
##################################################

make unschedule-offline-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Unschedule jobs for offline-compaction-snapshot
##################################################

make unschedule-offline-compaction-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

# ##################################################
# # List packages on AEM Author and AEM Publish
# ##################################################

make list-packages \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher

##################################################
# Enable and disable CRXDE on AEM Author and AEM Publish
##################################################

make enable-crxde \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher

make disable-crxde \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher

##################################################
# Flush AEM Dispatcher cache
##################################################

make flush-dispatcher-cache \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher

##################################################
# Deploy a set of artifacts to AEM Full-Set Architecture
##################################################

make deploy-artifacts-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  descriptor_file=deploy-artifacts-descriptor.json

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Deploy a single AEM package to AEM Author
##################################################

make deploy-artifact \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher \
  aem_id=author \
  source="$AEM_PACKAGE_URL" \
  group="$AEM_PACKAGE_GROUP" \
  name="$AEM_PACKAGE_NAME" \
  version="$AEM_PACKAGE_VERSION" \
  replicate=true \
  activate=false \
  force=true

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Deploy a single AEM package to AEM Publish
##################################################

make deploy-artifact \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher \
  aem_id=publish \
  source="$AEM_PACKAGE_URL" \
  group="$AEM_PACKAGE_GROUP" \
  name="$AEM_PACKAGE_NAME" \
  version="$AEM_PACKAGE_VERSION" \
  replicate=false \
  activate=false \
  force=true

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Export package from AEM Author to S3
##################################################

make export-package \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher \
	aem_id=author \
	package_group=shinesolutions \
	package_name=aem-helloworld-content \
	package_filter="[{'root':'/apps/helloworld','rules':[]},{'root':'/content/helloworld','rules':[{'modifier':'exclude','pattern':'.*.\\d*\\.\\d*\\.(png|jpeg|gif)'}]},{'root':'/etc/designs/helloworld','rules':[]}]"

##################################################
# Import package from S3 to AEM Author
##################################################

make import-package \
	stack_prefix="$STACK_PREFIX" \
	target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
	config_path="$CONFIG_PATH" \
	component=author-publish-dispatcher \
	aem_id=author \
	source_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
	package_group="$AEM_PACKAGE_GROUP" \
	package_name="$AEM_PACKAGE_NAME" \
	package_datestamp="$AEM_EXPORT_PACKAGE_DATE"

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Export package from AEM Publisher to S3
##################################################

make export-package \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher \
	aem_id=publish \
	package_group=shinesolutions \
	package_name=aem-helloworld-content \
	package_filter="[{'root':'/apps/helloworld','rules':[]},{'root':'/content/helloworld','rules':[{'modifier':'exclude','pattern':'.*.\\d*\\.\\d*\\.(png|jpeg|gif)'}]},{'root':'/etc/designs/helloworld','rules':[]}]"

##################################################
# Import package from S3 to AEM Publisher
##################################################

make import-package \
	stack_prefix="$STACK_PREFIX" \
	target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
	config_path="$CONFIG_PATH" \
	component=author-publish-dispatcher \
	aem_id=publish \
	source_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
	package_group="$AEM_PACKAGE_GROUP" \
	package_name="$AEM_PACKAGE_NAME" \
	package_datestamp="$AEM_EXPORT_PACKAGE_DATE"

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Take live snapshot of AEM Author and AEM Publish repositories
##################################################

make live-snapshot \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH" \
  component=author-publish-dispatcher

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Offline snapshot AEM Consolidated Architecture
##################################################

make offline-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Offline compaction snapshot AEM Consolidated Architecture
##################################################

make offline-compaction-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

make check-readiness-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Schedule jobs for live-snapshot
##################################################

make schedule-live-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Schedule jobs for offline-snapshot
##################################################

make schedule-offline-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"

##################################################
# Schedule jobs for offline-compaction-snapshot
##################################################

make schedule-offline-compaction-snapshot-consolidated \
  stack_prefix="$STACK_PREFIX" \
  target_aem_stack_prefix="$TARGET_AEM_STACK_PREFIX" \
  config_path="$CONFIG_PATH"
