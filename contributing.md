# Setup

```
brew install nvm
# complete nvm installation as per instructions

(cd ./local-server && nvm use)
brew install swiftformat
brew install --cask swiftformat-for-xcode
# Open Applications > SwiftFormat for Xcode
# > File > Open > ./app/rules.swiftformat
# Open Settings > General > Login Items & Extensions > Xcode > Enable SwiftFormat for Xcode
# Set a key binding for SwiftFormat in Xcode > Preferences > Key Bindings > Format File

brew install jc
brew install jq
brew install shfmt
cp -R ./tools/githooks/. .git/hooks
```

## App developement
See the [app's development guide](./app/contributing.md) for more details.

## Architecture overview
Xcompanion has a MacOS app and a local node server:
- the MacOS app handles all the UI/UX and intergration with Xcode.
- the local node server handles some business logic that leverages open source code written in typescript. Some examples include interfacing with external providers, defining some agentic tools etc. It's not worth re-building the wheel in Swift for the sake of it. The installation of node and the local server is managed by the MacOS app.
