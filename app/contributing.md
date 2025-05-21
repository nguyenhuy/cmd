# MacOS App development

### High level structure
The app has two targets. A standard MacOS target for the host app, and an Xcode extension. The host app bundles and boots a local Node server. Most of the logic lives in the host app. The host app talks to the Xcode extension through the AX API (ie programatically tapping buttons in Xcode's menu) and the extension talks to the host app trough the local server that relays messages.

When open source implementations for some isolated features are avaialble in Typescript, we might include them in the local Node server and trigger them from the host app over http. An example is the creation and restauration of Checkpoints. This save development time and we can always port those features to Swift at a later time.

### Modularization
We favor a highly modularized code base. The motivation is to promote isolation and testing. It should also help with faster rebuild times and SwiftUI previews.

##### Module.swift
Each module defines a `Module.swift` file where its dependencies are listed. They don't make sense on their own, but are are aggregated to create the shared [`Package.swift`](./modules/Package.swift) that is a standard Swift package.
The `Module.swift` are the source of thruth and the `Package.swift` is a derived artifact. If you need to make ad-hoc changes to `Package.swift`, edit its template `Package.base.swift`.

##### syncing dependencies
`make sync-dependencies` aggregates all dependencies, detect missing & unused ones and fix them, and generate a local `Package.swift` for each module. The latter is not checked in. It allows to open and iterate on just one module and its required dependencies instead of all of the codebase.

##### 3rd party
3rd party dependencies need to be written manually in the corresponding `Module.swift`, and new ones also need to be added to `Package.base.swift`.

##### Modules structure
- foundation: usually some utility with no or little dependencies.
- coreUI: reusable UI components
- service: handle a specific role (for example networking). They define an interface and an implementation. They usually behave like a singleton.
- feature: one specific feature. This will likely contain UI, state management etc (which could also be modularized in a service for more complex states)
- plugin: plugin points where handlers can be registered to from different parts of the app.

| Depends on →<br>Module Type ↓ | foundation | coreUI | service interface | service implementation | plugin |
|----------------------------------|------------|---------|------------------|----------------------|--------|
| foundation | ✅ | ❌ | ❌ | ❌ | ❌ |
| coreUI | ✅ | ✅ | ❌ | ❌ | ❌ |
| service interface | ✅ | ❌ | ✅ | ❌ | ❌ |
| service implementation | ✅ | ❌ | ✅ | ❌ | ❌ |
| plugin | ✅ | ❌ | ❌ | ❌ | ❌ |
| app | ✅ | ✅ | ✅ | ✅ | ✅ |

### Tips

If for some reason Xcode stops showing files in Swift packages, removing untracked files from `./modules` will help:
```bash
make clean
```
