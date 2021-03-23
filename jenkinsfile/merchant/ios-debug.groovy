#!groovy
library 'pipeline-shared-library'

def baseMap = BaseConfig()
def appMap = MerchantConfig()
def configMap = DebugConfig()
def map = baseMap + appMap + configMap
pipelineMerchant(map)
