#!groovy
library 'pipeline-shared-library'

def commonConfig = config_common()

def platformConfigIOS = config_platform_ios()
def platformConfigAndroid = config_platform_android()
def platformConfigs = ['ios': platformConfigIOS, 'android': platformConfigAndroid]

def appConfigMerchant = config_app_merchant()
def appConfigHatch = config_app_hatch()
def appConfigCustomer = config_app_customer()
def appConfigs = ['merchant': appConfigMerchant, 'customer': config_app_customer, 'hatch': appConfigHatch]

def buildConfigDebug = config_build_debug([:])
def buildConfigUAT = config_build_uat([:])
def buildConfigRelease = config_build_release([:])
def buildConfigs = ['debug': buildConfigDebug, 'uat': buildConfigUAT, 'release': buildConfigRelease]

def map = commonConfig + platformConfigs + appConfigs + buildConfigs
pipeline_snapshot(map)
