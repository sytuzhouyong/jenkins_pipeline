def call() {
    def map = [:]
    // app标识
    map.put('AppIdentifier', 'hatch')
    // Git仓库地址
    map.put('GitURL', 'git@192.168.2.246:mobile-dev/zn_hatch.git')
    // Bundle id
    map.put('AppPackageId', 'com.znlh.hatch')
    // 描述文件名称
    map.put('ProvisioningProfileDev', 'znhatch_dev0623')
    map.put('ProvisioningProfileAdhoc', 'znhatch_adhoc0623')
    map.put('ProvisioningProfileRelease', 'znhatch_appstore')
    // 描述文件uuid
    map.put('ProvisioningProfileUUIDDev', 'd9992dd2-cf67-438f-94ff-ca39fc17771a')
    map.put('ProvisioningProfileUUIDAdhoc', 'c5d0aee7-1ad4-43d2-9984-848b3604f70d')
    map.put('ProvisioningProfileUUIDRelease', '46d7f62b-eedd-462b-aba1-e32c480c0e08')
    // 分支信息
    def branches = '''\
feat/3.1.0
feat/3.0.1
feat/init
stable
'''
    map.put('MainBranch', branches)

    // App内接口环境
    def appHostEnvNew = '''\
https://dmo.znlhzl.cn
https://uatdmo.znlhzl.cn
http://sit.pla.gate.znlhzl.org
http://192.168.2.209:9090
'''
    map.put('AppHostEnvNew', appHostEnvNew)
    def appHostEnvOld = '''\
https://api.znlhzl.cn
https://uatapi.znlhzl.cn
http://sit.pla.zuul.znlhzl.org
http://dev.pla.zuul.znlhzl.org
'''
    map.put('AppHostEnvOld', appHostEnvOld)
    

    return map
}