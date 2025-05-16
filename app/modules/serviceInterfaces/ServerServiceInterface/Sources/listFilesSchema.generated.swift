// swiftformat:disable all
// This file is generated from ./local-server/src/server/schemas/listFilesSchema.ts by `yarn export-schema-swift`.
// Do not edit it manually.

import Foundation
import JSONFoundation

extension Schema {
  public struct ListFilesToolInput: Codable, Sendable {
    public let projectRoot: String
    public let path: String
    public let recursive: Bool?
  
    private enum CodingKeys: String, CodingKey {
      case projectRoot = "projectRoot"
      case path = "path"
      case recursive = "recursive"
    }
  
    public init(
        projectRoot: String,
        path: String,
        recursive: Bool? = nil
    ) {
      self.projectRoot = projectRoot
      self.path = path
      self.recursive = recursive
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      projectRoot = try container.decode(String.self, forKey: .projectRoot)
      path = try container.decode(String.self, forKey: .path)
      recursive = try container.decodeIfPresent(Bool?.self, forKey: .recursive)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(projectRoot, forKey: .projectRoot)
      try container.encode(path, forKey: .path)
      try container.encodeIfPresent(recursive, forKey: .recursive)
    }
  }
  public struct ListFilesToolOutput: Codable, Sendable {
    public let files: [ListedFileInfo]
    public let hasMore: Bool
  
    private enum CodingKeys: String, CodingKey {
      case files = "files"
      case hasMore = "hasMore"
    }
  
    public init(
        files: [ListedFileInfo],
        hasMore: Bool
    ) {
      self.files = files
      self.hasMore = hasMore
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      files = try container.decode([ListedFileInfo].self, forKey: .files)
      hasMore = try container.decode(Bool.self, forKey: .hasMore)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(files, forKey: .files)
      try container.encode(hasMore, forKey: .hasMore)
    }
  }
  public struct ListedFileInfo: Codable, Sendable {
    public let path: String
    public let isFile: Bool
    public let isDirectory: Bool
    public let isSymlink: Bool
    public let byteSize: Int
    public let permissions: String
    public let createdAt: String
    public let modifiedAt: String
  
    private enum CodingKeys: String, CodingKey {
      case path = "path"
      case isFile = "isFile"
      case isDirectory = "isDirectory"
      case isSymlink = "isSymlink"
      case byteSize = "byteSize"
      case permissions = "permissions"
      case createdAt = "createdAt"
      case modifiedAt = "modifiedAt"
    }
  
    public init(
        path: String,
        isFile: Bool,
        isDirectory: Bool,
        isSymlink: Bool,
        byteSize: Int,
        permissions: String,
        createdAt: String,
        modifiedAt: String
    ) {
      self.path = path
      self.isFile = isFile
      self.isDirectory = isDirectory
      self.isSymlink = isSymlink
      self.byteSize = byteSize
      self.permissions = permissions
      self.createdAt = createdAt
      self.modifiedAt = modifiedAt
    }
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      path = try container.decode(String.self, forKey: .path)
      isFile = try container.decode(Bool.self, forKey: .isFile)
      isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
      isSymlink = try container.decode(Bool.self, forKey: .isSymlink)
      byteSize = try container.decode(Int.self, forKey: .byteSize)
      permissions = try container.decode(String.self, forKey: .permissions)
      createdAt = try container.decode(String.self, forKey: .createdAt)
      modifiedAt = try container.decode(String.self, forKey: .modifiedAt)
    }
  
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(path, forKey: .path)
      try container.encode(isFile, forKey: .isFile)
      try container.encode(isDirectory, forKey: .isDirectory)
      try container.encode(isSymlink, forKey: .isSymlink)
      try container.encode(byteSize, forKey: .byteSize)
      try container.encode(permissions, forKey: .permissions)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(modifiedAt, forKey: .modifiedAt)
    }
  }}
