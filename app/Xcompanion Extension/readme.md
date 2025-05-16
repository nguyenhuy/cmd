## Running the extension

Xcode will show the extension in the Editor menu after the permission (login item & extensions > Xcode extension) has been granted.
The extension will be disabled if:
- the permission was granted after Xcode started (ie you need to relaunch Xcode)
- the code in the extension has changed (ie you re-installed the app, or rebuild it)

When not developping the extension, set the setting `pointReleaseXcodeExtensionToDebugApp` to true in the DEBUG app. This will make the DEBUG build talk with the RELEASE extension, allowing for it to interact with an extension that is enabled.

When developping the extension, set the setting `pointReleaseXcodeExtensionToDebugApp` to false in the DEBUG app. Building the extension will launch a new instance of Xcode. Make sure that any logic that relies on identifying a specific instance of Xcode works well then.
