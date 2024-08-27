#!/bin/bash


APP_NAME="PanoCapture"
PKG_NAME="$APP_NAME.pkg"
APP_PATH="build/Release/PanoCapture.app"

xcodebuild
# 创建 PKG 文件
pkgbuild --root $APP_PATH \
         --identifier "com.janlely.${APP_NAME}" \
         --version "1.0" \
         "$PKG_NAME"

echo "PKG 文件已创建：$PKG_NAME"
