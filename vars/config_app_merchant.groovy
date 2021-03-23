def call(Map platformMap) {
    def map = [:]
    // app标识
    map.put('AppIdentifier', 'merchant')
    // Git仓库地址
    map.put('GitURL', 'git@192.168.2.246:mobile-dev/merchant_flutter.git')
    // Bundle id
    def appId = "com.znlhzl.znlhzl"
    if (platformMap) {
        if (platformMap["Platform"].equalsIgnoreCase("ios")) {
            appId = "com.znlh.as.bussiness"
        }
    }
    map.put("AppPackageId", appId)
    // 描述文件名称
    // security cms -D -i  x.mobileprovision  
    map.put('ProvisioningProfileDev', 'business_dev_0211_001')
    map.put('ProvisioningProfileAdhoc', 'business_adhoc_0104')
    map.put('ProvisioningProfileRelease', 'bussiness_dis')
    // 描述文件uuid
    map.put('ProvisioningProfileUUIDDev', 'f25fdbcb-20c6-4f0e-90ef-b8db24b48549')
    map.put('ProvisioningProfileUUIDAdhoc', '712d036d-c3f2-4fb0-ad10-4b95894568ab')
    map.put('ProvisioningProfileUUIDRelease', 'f8eaafe4-9e7e-4452-a9b0-d1c915d67d9e')
    // 分支信息
    def branches = '''\
master
stable
sit/sal
sit/sev
sit/opr
sit/iot
stable_3
'''
    map.put('MainBranch', branches)
    map.put('BaseBranch', branches)
    map.put('CommonBranch', branches)
    map.put('SalBranch', branches)
    map.put('SevBranch', branches)
    map.put('LgtBranch', branches)
    map.put('FinBranch', branches)
    map.put('MhsBranch', branches)

    // App内接口环境以及第三方key环境，如高德地图，极光推送
    def appHostEnv = '''\
https://api.znlhzl.cn/
https://uatapi.znlhzl.cn/
https://uat2api.znlhzl.cn/
http://dev.sev.api.znlhzl.org/
'''
    map.put('AppHostEnv', appHostEnv)

    // 动态发布后台接口地址
    def dynamicHostEnv = '''\
https://api.znlhzl.cn
https://uatapi.znlhzl.cn
https://uat2api.znlhzl.cn
http://sit.pla.zuul.znlhzl.org
'''
    map.put('DynamicHostEnv', dynamicHostEnv)

    return map
}