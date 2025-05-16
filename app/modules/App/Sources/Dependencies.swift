// Copyright Xcompanion. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

import AppEventService
import AppEventServiceInterface
import AppKit
import CheckpointService
import CheckpointServiceInterface
import Combine
import Dependencies
import FileEditService
import FileEditServiceInterface
import FileSuggestionService
import FileSuggestionServiceInterface
import Foundation
import FoundationInterfaces
import LLMService
import LLMServiceInterface
import LoggingServiceInterface
import PermissionsService
import PermissionsServiceInterface
import ServerService
import ServerServiceInterface
import SettingsService
import SettingsServiceInterface
import ShellService
import ShellServiceInterface
import ToolFoundation
import XcodeControllerService
import XcodeControllerServiceInterface
import XcodeObserverService
import XcodeObserverServiceInterface

// MARK: - AppEventHandlerRegistryDependencyKey + DependencyKey

extension AppEventHandlerRegistryDependencyKey: DependencyKey {
  public static var liveValue: AppEventHandlerRegistry { AppScope.shared.appEventHandlerRegistry }
}

// MARK: - AppsActivationStateDependencyKey + DependencyKey

extension AppsActivationStateDependencyKey: DependencyKey {
  public static var liveValue: AnyPublisher<AppsActivationState, Never> {
    AppScope.shared.appsActivationState
  }
}

// MARK: - CheckpointServiceDependencyKey + DependencyKey

extension CheckpointServiceDependencyKey: DependencyKey {
  public static var liveValue: CheckpointService { AppScope.shared.checkpointService }
}

// MARK: - FileEditServiceDependencyKey + DependencyKey

extension FileEditServiceDependencyKey: DependencyKey {
  public static var liveValue: FileEditService { AppScope.shared.fileEditService }
}

// MARK: - FileManagerDependencyKey + DependencyKey

extension FileManagerDependencyKey: DependencyKey {
  public static var liveValue: FileManagerI {
    FileManager.default
  }
}

// MARK: - FileSuggestionServiceDependencyKey + DependencyKey

extension FileSuggestionServiceDependencyKey: DependencyKey {
  public static var liveValue: FileSuggestionService { AppScope.shared.fileSuggestionService }
}

// MARK: - LLMServiceDependencyKey + DependencyKey

extension LLMServiceDependencyKey: DependencyKey {
  public static var liveValue: LLMService { AppScope.shared.llmService }
}

// MARK: - PermissionsServiceDependencyKey + DependencyKey

extension PermissionsServiceDependencyKey: DependencyKey {
  public static var liveValue: PermissionsService { AppScope.shared.permissionsService }
}

// MARK: - ServerDependencyKey + DependencyKey

extension ServerDependencyKey: DependencyKey {
  public static var liveValue: Server { AppScope.shared.server }
}

// MARK: - SettingsServiceDependencyKey + DependencyKey

extension SettingsServiceDependencyKey: DependencyKey {
  public static var liveValue: SettingsService { AppScope.shared.settingsService }
}

// MARK: - SharedUserDefaultsDependencyKey + DependencyKey

extension SharedUserDefaultsDependencyKey: DependencyKey {
  public static var liveValue: any UserDefaultsI { AppScope.shared.sharedUserDefaults }
}

// MARK: - ShellServiceDependencyKey + DependencyKey

extension ShellServiceDependencyKey: DependencyKey {
  public static var liveValue: ShellService { AppScope.shared.shellService }
}

// MARK: - ToolsPluginDependencyKey + DependencyKey

extension ToolsPluginDependencyKey: DependencyKey {
  public static var liveValue: ToolsPlugin { AppScope.shared.toolsPlugin }
}

// MARK: - XcodeControllerDependencyKey + DependencyKey

extension XcodeControllerDependencyKey: DependencyKey {
  public static var liveValue: XcodeController { AppScope.shared.xcodeController }
}

// MARK: - XcodeObserverDependencyKey + DependencyKey

extension XcodeObserverDependencyKey: DependencyKey {
  public static var liveValue: XcodeObserver { AppScope.shared.xcodeObserver }
}

// MARK: - AppScope + AppEventHandlerRegistryProviding

extension AppScope: AppEventHandlerRegistryProviding { }

// MARK: - AppScope + AppsActivationStateProviding

extension AppScope: AppsActivationStateProviding { }

// MARK: - AppScope + CheckpointServiceProviding

extension AppScope: CheckpointServiceProviding { }

// MARK: - AppScope + FileEditServiceProviding

extension AppScope: FileEditServiceProviding { }

// MARK: - AppScope + FileManagerProviding

extension AppScope: FileManagerProviding { }

// MARK: - AppScope + IsHostAppActiveProviding

extension AppScope: IsHostAppActiveProviding {
  var isHostAppActive: AnyPublisher<Bool, Never> {
    sharedDependencies!.isAppActive
  }
}

// MARK: - AppScope + LLMServiceProviding

extension AppScope: LLMServiceProviding { }

// MARK: - AppScope + PermissionsServiceProviding

extension AppScope: PermissionsServiceProviding { }

// MARK: - AppScope + ServerProviding

extension AppScope: ServerProviding { }

// MARK: - AppScope + SettingsServiceProviding

extension AppScope: SettingsServiceProviding { }

// MARK: - AppScope + ShellServiceProviding

extension AppScope: ShellServiceProviding { }

// MARK: - AppScope + ToolsPluginProviding

extension AppScope: ToolsPluginProviding { }

// MARK: - AppScope + UserDefaultsProviding

extension AppScope: UserDefaultsProviding {
  var sharedUserDefaults: any UserDefaultsI {
    shared {
      do {
        guard let userDefaults = try UserDefaults.shared(bundle: Bundle(for: AppScope.self)) else {
          return Foundation.UserDefaults.standard
        }
        return userDefaults
      } catch {
        return Foundation.UserDefaults.standard
      }
    }
  }
}

// MARK: - AppScope + XcodeControllerProviding

extension AppScope: XcodeControllerProviding { }

// MARK: - AppScope + XcodeObserverProviding

extension AppScope: XcodeObserverProviding { }
