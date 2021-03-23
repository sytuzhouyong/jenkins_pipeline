#!groovy

def call(Map map) { 
  println('snapshot map = ' + map)
  pipeline {
    agent any
    options {
      timeout(time: 45, unit: 'MINUTES')
    }
    parameters {
      choice(name: 'AppIdentifier', choices: "merchant\nhatch", description: 'App标识')
      choice(name: 'Platform', choices: "ios\nandroid", description: '平台标识')
      choice(name: 'FlutterMode', choices: "${map.FlutterMode}", description: 'Flutter编译模式')
      string(name: 'BuildVersion', defaultValue: "${map.BuildVersion}", description: '版本号，可以为空，空的话取工程中的设置')
      choice(name: 'MiniProgrameType', choices: "${map.MiniProgrameType}", description: 'App分享到小程序的版本类型。\npreview: 体验版, release: 线上版本')
      choice(name: 'ApiHostSwitchOptions', choices: "${map.ApiHostSwitchOptions}", description: 'Host切换开关。\n开：可以切换, 关：不能切换')
      text(name:'GitSnapshot', defaultValue: '', description: 'git信息快照')
    }
    environment {
      // AppPackageId = "${map.AppPackageId}"
      // DevelopTeam = "${map.DevelopTeam}"
      // CodeSignIdentityDev = "${map.CodeSignIdentityDev}"
      // CodeSignIdentityDis = "${map.CodeSignIdentityDis}"
      // ProvisioningProfileDev = "${map.ProvisioningProfileDev}"
      // ProvisioningProfileAdhoc = "${map.ProvisioningProfileAdhoc}"
      // ProvisioningProfileRelease = "${map.ProvisioningProfileRelease}"
      BuildString = "${map.BuildString}"
      BuildNumber = "${map.BuildNumber}"
    }
    stages {
      stage('环境准备') {
        steps {
          script {
            if (params.Platform == 'ios') {
              map = map + map['ios']
              println('1111')
            } else if (params.Platform == 'android') {
              map = map + map['android']
            }
            println('22222')
          }
          echo "map.FlutterSDKHome = ${map.FlutterSDKHome}"
        }
      }
      stage('二次参数选择1') {
        steps {
          echo "111111: ${map.FlutterSDKHome}"
        }
      }
      stage('二次参数选择') {
        input {
          message "继续选择"
          ok "确定"
          parameters {
            choice(name: 'FlutterSDKHome', choices: "${map.FlutterSDKHome}", description: 'Flutter版本选择')
            // choice(name: 'AppPackageType', choices: "${map.AppPackageType}", description: '打包类型')
            // choice(name: 'AppHostEnv', choices: "${map.AppHostEnv}", description: 'App内接口环境')
          }
        }
        steps {
          echo "${map.FlutterSDKHome}"
        }
      }
      stage('拷贝脚本文件') {
        steps {
          deleteDir()
          sh "${WORKSPACE}/../${JOB_NAME}@libs/pipeline-shared-library/scripts/check_third_library.sh"
        }
      }
      stage('代码复原') {
        steps {
          writeFile encoding: 'utf8', file: 'git_snapshot.txt', text: "${GitSnapshot}"
          sh label: '代码复原', script:
          '''
            source ./scripts/code_snapshot.sh
            parseGitSnapshotInfo git_snapshot.txt
          '''
        }
      }
      stage('环境检测') { steps { dir('./scripts') { sh "./check_env_code.sh" } } }
      stage('编译') { steps { dir('./scripts') { sh "./compile.sh" } } }
      stage('打包') {
        steps {
          dir('./scripts') { sh "./make_package.sh" }
          archiveArtifacts allowEmptyArchive: true, artifacts: 'ios/build/*.ipa, scripts/*.txt, build/app/*.apk, channelPackages/*.apk', onlyIfSuccessful: true
        }
      }
    }
  }
}
