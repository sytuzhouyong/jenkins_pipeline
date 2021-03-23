#!groovy

def call(Map map) {
  // println("merchant map = " + map);

  pipeline {
    agent any
    options {
      timeout(time: 45, unit: 'MINUTES')
    }
    parameters {
      choice(name: 'FlutterSDKHome', choices: "${map.FlutterSDKHome}",, description: 'Flutter版本选择')
      choice(name: 'MainBranch', choices: "${map.MainBranch}", description: '主工程分支，包括子模块的分支')
      choice(name: 'BaseBranch', choices: "${map.BaseBranch}", description: 'base库分支')
      choice(name: 'CommonBranch', choices: "${map.CommonBranch}", description: 'common库分支')
      choice(name: 'SalBranch', choices: "${map.SalBranch}", description: '销售库分支')
      choice(name: 'SevBranch', choices: "${map.SevBranch}", description: '服务库分支')
      choice(name: 'LgtBranch', choices: "${map.LgtBranch}", description: '供应链库分支')
      choice(name: 'FinBranch', choices: "${map.FinBranch}", description: '财务线库分支')
      choice(name: 'MhsBranch', choices: "${map.MhsBranch}", description: '机手线库分支')
      string(name: 'BuildVersion', defaultValue: "${map.BuildVersion}", description: '版本号，可以为空，空的话取工程中的设置')
      choice(name: 'AppHostEnv', choices: "${map.AppHostEnv}", description: 'App内接口环境')
      choice(name: 'MiniProgrameType', choices: "${map.MiniProgrameType}", description: 'App分享到小程序的版本类型。\npreview: 体验版, release: 线上版本')
      choice(name: 'ApiHostSwitchOptions', choices: "${map.ApiHostSwitchOptions}", description: 'Host切换开关。\n开：可以切换, 关：不能切换')
      choice(name: 'EnableAutoTest', choices: "${map.EnableAutoTest}", description: '自动化测试开关。\n开：可以跑自动化脚本, 关：不能跑自动化脚本')
    }
    environment {
      AppPackageId = "${map.AppPackageId}"
      AppPackageType = "${map.AppPackageType}"
      DevelopTeam = "${map.DevelopTeam}"
      CodeSignIdentityDev = "${map.CodeSignIdentityDev}"
      CodeSignIdentityDis = "${map.CodeSignIdentityDis}"
      ProvisioningProfileDev = "${map.ProvisioningProfileDev}"
      ProvisioningProfileAdhoc = "${map.ProvisioningProfileAdhoc}"
      ProvisioningProfileRelease = "${map.ProvisioningProfileRelease}"
      FlutterMode = "${map.FlutterMode}"
      BuildString = "${map.BuildString}"
      BuildNumber = "${map.BuildNumber}"
      AppIdentifier = "${map.AppIdentifier}"
      Platform = "${map.Platform}"
      PlatformPretty = "${map.PlatformPretty}"
      isLegu = "${map.isLegu}"
    }
    stages {
      stage('主工程代码下载') {
        steps {
          echo "主工程代码下载 ${MainBranch}"
          git(url: "${map.GitURL}", branch: "${MainBranch}", changelog: true, credentialsId: "git.znlh.com")
          sh "bash ${WORKSPACE}/../${JOB_NAME}@libs/pipeline-shared-library/scripts/check_third_library.sh"
        }
      }
      stage('三方库下载') {
        steps {
          dir('./scripts') {
            sh label: '下载第三方库', script:
            '''
              ./update_code.sh \
                --has-submodule=1 \
                --modules="BaseBranch ComBranch SalBranch SevBranch LgtBranch FinBranch MhsBranch" \
                --branches="${BaseBranch} ${CommonBranch} ${SalBranch} ${SevBranch} ${LgtBranch} ${FinBranch} ${MhsBranch}"

              if [ "${Platform}" = "android" ]; then
                cd ${WORKSPACE}/android
                bash ./pull_module.sh
              fi
            '''
          }
        }
      }
      stage('环境检测') { steps { dir('./scripts') { sh "bash ./check_env_code.sh" } } }
      stage('编译') { steps { dir('./scripts') { sh "bash ./compile.sh" } } }
      stage('打包') {
        steps {
          dir('./scripts') { sh "bash ./make_package.sh" }
          archiveArtifacts allowEmptyArchive: true, artifacts: 'scripts/*.txt, channelPackages/*.apk', onlyIfSuccessful: true
        }
      }
      stage('上传蒲公英') {
        when { 
          anyOf { 
            environment name: 'AppPackageType', value: 'adhoc' 
            environment name: 'AppPackageType', value: 'release'
          } 
        }
        steps { 
          dir('./scripts') { sh "bash ./upload_pgy.sh" }
          archiveArtifacts allowEmptyArchive: false, artifacts: 'scripts/*.txt, scripts/*.html', onlyIfSuccessful: true
        }
      }
    }
    post {
      success { dir('./scripts') { sh "bash ./trigger_dingtalk.sh" } }
      failure { dir('./scripts') { sh "bash ./trigger_dingtalk.sh failed" } }
    }
  }
}
