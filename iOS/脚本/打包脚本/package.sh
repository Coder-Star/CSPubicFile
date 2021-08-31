#!/bin/sh

# 注意事项
# 1、如果提示permission denied: ./package.sh ， 则先附加权限，命令如下：chmod 777 package.sh
# 2、请根据自己项目的情况选择使用 workspace 还是 project 形式，目前默认为 workspace 形式

### 需要根据自己项目的情况进行修改，XXX都是需要进行修改的，可搜索进行修改 ###

# Project名称
PROJECT_NAME=XXX

## Scheme名
SCHEME_NAME=XXX

## 编译类型 Debug/Release二选一
BUILD_TYPE=XXX

## 项目根路径，xcodeproj/xcworkspace所在路径
PROJECT_ROOT_PATH=XXX

## 打包生成路径
PRODUCT_PATH=XXX

## ExportOptions.plist文件的存放路径，该文件描述了导出ipa文件所需要的配置
## 如果不知道如何配置该plist，可直接使用xcode打包ipa结果文件夹的ExportOptions.plist文件
EXPORTOPTIONSPLIST_PATH=XXX


## workspace路径
WORKSPACE_PATH=${PROJECT_ROOT_PATH}/${PROJECT_NAME}.xcworkspace

## project路径
PROJECT_PATH=${PROJECT_ROOT_PATH}/${PROJECT_NAME}.xcodeproj

### 编译打包过程 ###

echo "============Build Clean Begin============"

## 清理缓存

## project形式
# xcodebuild clean -project ${PROJECT_PATH} -scheme ${SCHEME_NAME} -configuration ${BUILD_TYPE} || exit

## workspace形式
xcodebuild clean -workspace ${WORKSPACE_PATH} -scheme ${SCHEME_NAME} -configuration ${BUILD_TYPE} || exit

echo "============Build Clean End============"

#获取Version
VERSION_NUMBER=`sed -n '/MARKETING_VERSION = /{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' ${PROJECT_PATH}/project.pbxproj`
# 获取build
BUILD_NUMBER=`sed -n '/CURRENT_PROJECT_VERSION = /{s/CURRENT_PROJECT_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' ${PROJECT_PATH}/project.pbxproj`

## 编译开始时间,注意不可以使用标点符号和空格
BUILD_START_DATE="$(date +'%Y-%m-%d_%H-%M')"

## IPA所在目录路径
IPA_DIR_NAME=${VERSION_NUMBER}_${BUILD_NUMBER}_${BUILD_START_DATE}

##xcarchive文件的存放路径
ARCHIVE_PATH=${PRODUCT_PATH}/IPA/${IPA_DIR_NAME}/${SCHEME_NAME}.xcarchive
## ipa文件的存放路径
IPA_PATH=${PRODUCT_PATH}/IPA/${IPA_DIR_NAME}

# 解锁钥匙串 -p后跟为电脑密码
security unlock-keychain -p XXX

echo  "============Build Archive Begin============"
## 导出archive包

## project形式
# xcodebuild archive -project ${PROJECT_PATH} -scheme ${SCHEME_NAME} -archivePath ${ARCHIVE_PATH}

## workspace形式
xcodebuild archive -workspace ${WORKSPACE_PATH} -scheme ${SCHEME_NAME} -archivePath ${ARCHIVE_PATH} -quiet || exit

echo "============Build Archive Success============"


echo "============Export IPA Begin============"
## 导出IPA包
xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath ${IPA_PATH} -exportOptionsPlist ${EXPORTOPTIONSPLIST_PATH} -quiet || exit

if [ -e ${IPA_PATH}/${SCHEME_NAME}.ipa ];
    then
    echo "============Export IPA SUCCESS============"
    open ${IPA_PATH}
    else
    echo "============Export IPA FAIL============"
fi


# 删除Archive文件，可根据各自情况选择是否保留
# rm -r ${ARCHIVE_PATH}


### 上传过程 ###

## 上传app store

# 验证
# xcrun altool --validate-app -f ${IPA_PATH}/${SCHEME_NAME}.ipa -t ios --apiKey xxx --apiIssuer xxx --verbose

# 上传
# xcrun altool --upload-app -f ${IPA_PATH}/${SCHEME_NAME}.ipa -t ios --apiKey xxx --apiIssuer xxx --verbose

## 上传到蒲公英
echo "============Upload PGYER Begin============"

## 具体参数可见 http://www.pgyer.com/doc/view/api#uploadApp
PGYER_UPLOAD_RESULT=`curl \
-F "file=@${IPA_PATH}/${SCHEME_NAME}.ipa" \
-F "buildInstallType=XXX" \
-F "buildPassword=XXX" \
-F "buildUpdateDescription=XXX" \
-F "_api_key=XXX" \
https://www.pgyer.com/apiv2/app/upload`

echo "============Upload PGYER SUCCESS============"
## 返回结果码，其中0为成功上传，因为返回结果中带回来的有中文显示乱码，无法利用jq解析


## 如需上传到fim，可查阅 https://www.betaqr.com/docs/publish 文档


### 如需脚本在执行过程中给用户提供选择，可使用以下Demo ###

#echo "Place enter the number you want to export? [ 1:app-store 2:ad-hoc] "
#read number
#    while([[ $number != 1 ]] && [[ $number != 2 ]])
#    do
#        echo "Error! Should enter 1 or 2"
#        echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "
#        read number
#    done
#if [ $number == 1 ];
#    then
#    ####
#    else
#    ####
#fi
