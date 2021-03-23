#!groovy
library 'pipeline-shared-library'

def commonConfig = config_common()
def platformConfig = config_platform_ios()
def appConfig = config_app_customer()
def buildConfig = config_build_snapshot(platformConfig)

def map = commonConfig + platformConfig + appConfig + buildConfig
pipeline_snapshot(map)
