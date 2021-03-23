
def call() {
    def map = [:]
    // app标识
    map.put('AppIdentifier', 'customer')
    // Git仓库地址
    map.put('GitURL', 'git@192.168.2.246:mobile-dev/zn_united_rentals.git')
    
    // Bundle Id
    map.put('AppPackageId', 'com.znlhzl.znlhzl.credit')
    // 描述文件
    map.put('ProvisioningProfileDev', 'zn_credit_dev')
    map.put('ProvisioningProfileAdhoc', 'zn_credit_adhoc')
    map.put('ProvisioningProfileRelease', 'zn_credit_dis')
    // 描述文件uuid
    map.put('ProvisioningProfileUUIDDev', '0d3b71d0-09fa-4901-bd60-9ad2b1e6c366')
    map.put('ProvisioningProfileUUIDAdhoc', '22f8f02d-7834-42f6-a5a7-996df544925e')
    map.put('ProvisioningProfileUUIDRelease', 'acb1661b-9bb0-48eb-bf70-b87d0ebde5e4')
    // 分支信息
    def branches = '''\
stable
feat/androidx_1.17.3
master
'''
    map.put('MainBranch', branches)
    map.put('ModuleBranch', branches)

    // App内接口环境以及第三方key环境
    def appHostEnv = '''\
https://dmo.znlhzl.cn
https://uatdmo.znlhzl.cn
https://uat2dmo.znlhzl.cn
http://sit.pla.gate.znlhzl.org
http://sit.dmo.znlhzl.org
http://dev.pla.gate.znlhzl.org
'''
    map.put('AppHostEnv', appHostEnv)

    return map
}