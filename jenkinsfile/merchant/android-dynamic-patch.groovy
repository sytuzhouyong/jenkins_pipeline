#!groovy
library 'pipeline-shared-library'

def baseMap = BaseConfig()
def appMap = MerchantConfig()
def configMap = UATConfig()
def map = baseMap + appMap + configMap
pipelineDynamicPatch(map)
