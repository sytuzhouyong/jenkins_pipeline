#!groovy
library 'pipeline-shared-library'

def commonConfig = config_common()
def platformConfig = config_platform_android()
def appConfig = config_app_merchant(platformConfig)
def buildConfig = config_build_release(platformConfig)

def map = commonConfig + platformConfig + appConfig + buildConfig
pipeline_app_merchant(map)
