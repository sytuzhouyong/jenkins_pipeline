#!groovy
library 'pipeline-shared-library'

def commonConfig = config_common()
def platformConfig = config_platform_android()
def appConfig = config_app_hatch()
def buildConfig = config_build_uat(platformConfig)

def map = commonConfig + platformConfig + appConfig + buildConfig
pipeline_app_hatch(map)
