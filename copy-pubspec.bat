@echo off
call set-build-env.bat

sed "s/$VERSION_NUMBER/%VERSION_NUMBER%/g; s/$BUILD_NUMBER/%BUILD_NUMBER%/g" pubspec.template.yaml > pubspec.yaml