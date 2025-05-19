# Development

## High level design

### Modularization
We favor a highly modularized code base. The motivation is to promote isolation and testing. It should also help with faster rebuild times and SwiftUI previews.

Each module defines a `Module.swift` file where its dependencies are listed. They are aggregated to create the shared `Package.swift`.

Local dependencies are automatically added / removed by running:
```bash
./tools/dependencies/sync.sh
```
3rd party dependencies need to be written manually in the corresponding `Module.swift`, and new ones also need to be added to `Package.base.swift`.

We define different module types that have some dependency rules:
- foundation: usually some utility with no or little dependencies.
- coreUI: reusable UI components
- service: handle a specific role (for example networking). They define an interface and an implementation.
- feature: one specific feature. This will likely contain UI, state management etc (which could also be modularized in a service for more complex states)
- plugin: plugin points where handlers can be registered to from different parts of the app.

| Depends on →<br>Module Type ↓ | foundation | coreUI | service interface | service implementation | plugin |
|----------------------------------|------------|---------|------------------|----------------------|--------|
| foundation | ✅ | ❌ | ❌ | ❌ | ❌ |
| coreUI | ✅ | ✅ | ❌ | ❌ | ❌ |
| service interface | ✅ | ❌ | ❌ | ✅ | ❌ |
| service implementation | ✅ | ❌ | ✅ | ❌ | ❌ |
| plugin | ✅ | ❌ | ❌ | ❌ | ❌ |
| app | ✅ | ✅ | ✅ | ✅ | ✅ |

### Tips

If for some reason Xcode stops showing files in Swift packages, removing untracked files from `./modules` will help:
```bash
(cd "$(git rev-parse --show-toplevel)/app/modules" && find . -not -path './.git/*' | git check-ignore --stdin | tr '\n' '\0' | xargs -0 rm -rf)
```
