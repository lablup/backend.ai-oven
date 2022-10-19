#! /bin/bash

target_versions="3.9.15 3.10.8"

for version in $target_versions; do
    major_minor=$(echo "${version}" | awk -F. '{printf("%s.%s",$1,$2)}')
    pkgutil --pkgs | grep "PythonFramework-${major_minor}" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Downloading https://www.python.org/ftp/python/${version}/python-${version}-macos11.pkg"
        curl "https://www.python.org/ftp/python/${version}/python-${version}-macos11.pkg" > "python-${version}-macos11.pkg"
        echo "Installing python ${version} on system"
        sudo installer -pkg "python-${version}-macos11.pkg" -target /
    fi
done
