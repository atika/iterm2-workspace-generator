#!/bin/bash

# Create macOS app bundles for every configuration files (plist) found in `elementsRoot > iTerm Configurations
# Rename the plist config like this my_workspace_launcher.plist to get an app name like that: `My Workspace Launcher.app`
# gem install titleize

elementsRoot="${HOME}/Dev/Resources"
appsDestination="$HOME/Applications/iTerm Workspaces"
signIdentifier="Developer ID Application: My Name (XXXXX)"
bundleCopyright="My Name © $(date +'%Y')"
bundleBaseIdentifier="com.myapps.iterm2."

configsPath="${elementsRoot}/iTerm Configurations"
scriptPath="${elementsRoot}/OpeniTermDeveloperWorkspace.applescript"
iconPath="${elementsRoot}/iTerm.icns"

mkdir -p "${appsDestination}"

while read config; do

	APP_NAME=$(ruby -e "require 'titleize'; puts \"$config\".gsub(/[_-]+/,' ').gsub('.plist','').titleize()") # middleman_server => Middleman Server
	BUNDLE="${appsDestination}/${APP_NAME}.app"

	echo -e "- Generating app \0033[32m${APP_NAME}\0033[0m"

	# Clean by removing old bundle
	[[ -d "${BUNDLE}" ]] && rm -rf "${BUNDLE}"

	# Compile the script to an app
	osacompile  -x -a 'x86_64' -o "${BUNDLE}" "$scriptPath"

	# Copy config file
	cp "${configsPath}/${config}" "${BUNDLE}/Contents/Resources/config.plist"

	# Copy icon file
	cp "${iconPath}" "${BUNDLE}/Contents/Resources/applet.icns"

	# Bundle infos plist
	identifier=$(ruby -e "puts \"${APP_NAME}\".gsub(/\s+/,'').downcase") # middlemanserver
	bundleIdentifier="${bundleBaseIdentifier}${identifier}"
	plistFile="${BUNDLE}/Contents/Info.plist"

	/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string \"$bundleIdentifier\"" "${plistFile}"
	/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string \"$bundleCopyright\"" "${plistFile}"
	/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string \"$(date +'%s')\"" "${plistFile}"

	# Remove resource fork (icon)
	xattr -cr "${BUNDLE}"

	# Sign the bundle
	if [[ ! -z "$signIdentifier" ]]
	then
		codesign -s "${signIdentifier}" -v "${BUNDLE}"
	fi

done < <(ls "${configsPath}")
