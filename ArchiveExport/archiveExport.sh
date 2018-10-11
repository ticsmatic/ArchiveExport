#!/bin/bash
# 
# NOTE:
# ticsmatic archiveExport script - Service for project which one or more scheme 
#
# USAGE:
# 1）copy the 'ArchiveExport' folder which includ this script to your project
# 2）specify the parameters for archiveExport.properties file 
# 3）./archiveExport.sh
# 
# 使用方法:
# Xcode 9以后先使用Xcode手动导出ipa包，然后将导出包文件夹内的ExportOptions.plist文件修改名称后替换掉ArchiveExport文件夹内你需要的plist文件
# 1) 将ArchiveExport整个文件夹拖入到项目主目录
# 2) 打开archiveExport.properties文件, 配置项目参数
# 3) 打开终端, cd到ArchiveExport文件夹
# 4) 输入 ./archiveExport.sh 命令
# 😊😊😊此脚本使用配置文件的方式读取打包参数进行打包, 如果一个项目有多个scheme，只使用一个配置文件难以满足多个scheme的打包需求，
# 所以此脚本扩展了命令行参数支持，如:-p -w -s -c -e -i -a", 使用脚本参数来再次自定义打包参数
# 如: ./archiveExport.sh -s yourProScheme -e ArchiveExport/BBExportOptionsAppStore.plist
# 
# 通常情况下, 你需要修改archiveExport.properties文件而不是当前的脚本文件

XCODEBUILD_CMD=xcodebuild
ALTOOLPATH_CMD="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"

function readParameter() {
  variable=$1
  shift 
  parameter=$1
  shift
  eval $variable="\"$(sed '/^\#/d' archiveExport.properties | grep $parameter | tail -n 1 | cut -d '=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')\""
}

# Run a set of commands with logging and error handling
function runCommand() {
  command=$1
  shift

  $command "$@"
  returnValue=$?
  if [[ $returnValue != 0 && $returnValue != 5 ]] ; then
    echo "ERROR - Command '$command $@' failed with error code: $returnValue"
    exit $returnValue
  fi
  echo
}

function archiveAndExport() {
  if [[ "$workspaceFile" != "" ]] ; then
    buildCmdPrefix="-workspace $workspaceFile"
  else
    buildCmdPrefix="-project $projectFile"
  fi

  xcodeCleanCmd="$XCODEBUILD_CMD clean $buildCmdPrefix -scheme $appScheme -configuration $configuration"
  xcodeArchiveCmd="$XCODEBUILD_CMD archive $buildCmdPrefix -scheme $appScheme -configuration $configuration -archivePath $archiveExportPath/$appScheme.xcarchive"
  xcodeExportCmd="$XCODEBUILD_CMD -exportArchive -archivePath $archiveExportPath/$appScheme.xcarchive -exportPath $archiveExportPath -exportOptionsPlist $exportOptionsPlist"

  runCommand "${xcodeCleanCmd[@]}"
  runCommand "${xcodeArchiveCmd[@]}"
  runCommand "${xcodeExportCmd[@]}"
}

function uploadToAppstore() {
  if [ -z "$appleUser" ] || [ -z "$appleSecrect" ]; then
    echo >&2 "ERROR - You must specify -u and -p parameters for altoolPath Cmd"
    exit 1
  fi
  "$ALTOOLPATH_CMD" --validate-app -f $1 -u "$appleUser" -p "$appleSecrect"
  returnValue=$?
  if [ $returnValue -eq 0 ]; then
    "$ALTOOLPATH_CMD" --upload-app -f $1 -u "$appleUser" -p "$appleSecrect"
  else 
    exit $returnValue
  fi
}

# read config file 
projectFile=''; readParameter projectFile 'project'
workspaceFile=''; readParameter workspaceFile 'workspace'
appScheme=''; readParameter appScheme 'appScheme'
configuration=''; readParameter configuration 'configuration'
exportOptionsPlist=''; readParameter exportOptionsPlist 'exportOptionsPlist'
infoPlistPath=''; readParameter infoPlistPath 'infoPlistPath'
archiveExportRootPath=''; readParameter archiveExportRootPath 'archiveExportRootPath'

appleUser=''; readParameter appleUser 'appleUser'
appleSecrect=''; readParameter appleSecrect 'appleSecrect'

## COMMAND LINE OPTIONS 
while getopts "p:w:s:c:e:i:a" arg; do
  case $arg in
    p ) projectFile=$OPTARG;;
    w ) workspaceFile=$OPTARG;;
    s ) appScheme=$OPTARG;;
    c ) configuration=$OPTARG;;
    e ) exportOptionsPlist=$OPTARG;;
    i ) infoPlistPath=$OPTARG;;
    a ) archiveExportRootPath=$OPTARG;;
  esac
done

# if the configuration is not specified then set to Release
if [ -z "$configuration" -o "$configuration" = " " ]; then
  configuration="Release"
fi

# if the archiveExportRootPath is not specified then set to ~/Desktop/Archives
if [ -z "$archiveExportRootPath" -o "$archiveExportRootPath" = " " ]; then
  archiveExportRootPath="~/Desktop/Archives"
fi

# according to the selected exportOptionsPlist file, calculate the method of distribution
case $exportOptionsPlist in
  *'AdHoc'* ) distributionType='AdHoc';;
  *'AppStore'* ) distributionType='AppStore';;
  *'Enterprise'* ) distributionType='Enterprise';;
  *'Development'* ) distributionType='Development';;
esac

# switch to project root dir
cd ..

# if the infoPlistPath is specified then set build version for export path
bundleVersion=''
if [[ -n $infoPlistPath ]]; then
  bundleShortVersion=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $infoPlistPath`
  bundleBuildVersion=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $infoPlistPath`
  bundleVersion="v${bundleShortVersion}_${bundleBuildVersion}"
fi
# set exportPath
archiveExportPath="$archiveExportRootPath/${appScheme}_${configuration}_${distributionType}_${bundleVersion}_$(date +%y%m%d%H%M)"

# clean, archive, export command
archiveAndExport

# upload to appstore
if [ $distributionType = "AppStore" ]; then
  uploadToAppstore $archiveExportPath/$appScheme.ipa
fi
