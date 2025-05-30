// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

@preconcurrency import Combine
import ConcurrencyFoundation
import Foundation

#if DEBUG
public final class MockSettingsService: SettingsService {

  public init(
    _ settings: Settings? = nil,
    defaultSettings: Settings = Settings(
      pointReleaseXcodeExtensionToDebugApp: false,
      allowAnonymousAnalytics: false))
  {
    self.defaultSettings = defaultSettings
    self.settings = CurrentValueSubject<Settings, Never>(settings ?? defaultSettings)
  }

  public func value<T: Equatable>(for keypath: KeyPath<Settings, T>) -> T {
    settings.value[keyPath: keypath]
  }

  public func liveValue<T: Equatable>(for keypath: KeyPath<Settings, T>) -> ReadonlyCurrentValueSubject<T, Never> {
    ReadonlyCurrentValueSubject(
      settings.value[keyPath: keypath],
      publisher: settings.map { $0[keyPath: keypath] }.removeDuplicates().eraseToAnyPublisher())
  }

  public func values() -> Settings {
    settings.value
  }

  public func liveValues() -> ReadonlyCurrentValueSubject<Settings, Never> {
    ReadonlyCurrentValueSubject(settings)
  }

  public func update<T>(setting: WritableKeyPath<Settings, T>, to value: T) {
    var newSettings = settings.value
    newSettings[keyPath: setting] = value

    settings.send(newSettings)
  }

  public func update(to newSettings: Settings) {
    settings.send(newSettings)
  }

  public func resetToDefault<T>(setting: WritableKeyPath<Settings, T>) {
    update(setting: setting, to: defaultSettings[keyPath: setting])
  }

  public func resetAllToDefault() {
    settings.send(defaultSettings)
  }

  private let defaultSettings: Settings
  private let settings: CurrentValueSubject<Settings, Never>
}
#endif
