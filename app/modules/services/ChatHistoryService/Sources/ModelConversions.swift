// Copyright command. All rights reserved.
// Licensed under the XXX License. See License.txt in the project root for license information.

//// Copyright command. All rights reserved.
//// Licensed under the XXX License. See License.txt in the project root for license information.
//
// import ChatFeatureInterface
// import ChatHistoryServiceInterface
// import Foundation
// import GRDB
//
//// MARK: - Record to Model Conversions
//
//
// extension ChatMessageContentModel {
//  init(from _: ChatMessageContentRecord, attachments _: [AttachmentModel]) {
//    fatalError()
////    self.init(
////      id: record.id,
////      type: record.type,
////      text: record.text,
////      projectRoot: record.projectRoot,
////      isStreaming: record.isStreaming,
////      signature: record.signature,
////      reasoningDuration: record.reasoningDuration,
////      toolName: record.toolName,
////      toolInput: record.toolInput,
////      toolResult: record.toolResult,
////      attachments: attachments,
////      createdAt: record.createdAt,
////      updatedAt: record.updatedAt)
//  }
// }
//
// extension ChatMessageModel {
//  init(from _: ChatMessageRecord, contents _: [ChatMessageContentModel]) {
//    fatalError()
////    self.init(
////      id: record.id,
////      role: record.role,
////      contents: contents,
////      createdAt: record.createdAt,
////      updatedAt: record.updatedAt)
//  }
// }
//
// extension ChatEventModel {
//  init(from _: ChatEventRecord, messageContent _: ChatMessageContentModel? = nil) {
//    fatalError()
////    self.init(
////      id: record.id,
////      type: record.type,
////      messageContent: messageContent,
////      checkpointId: record.checkpointId,
////      role: record.role,
////      failureReason: record.failureReason,
////      createdAt: record.createdAt,
////      orderIndex: record.orderIndex)
//  }
// }
//
// extension ChatThreadModel {
//  init(from _: ChatThreadRecord, messages _: [ChatMessageModel], events _: [ChatEventModel]) {
//    fatalError()
////    self.init(
////      id: record.id,
////      name: record.name,
////      messages: messages,
////      events: events,
////      createdAt: record.createdAt,
////      updatedAt: record.updatedAt,
////      projectPath: record.projectPath,
////      projectRootPath: record.projectRootPath)
//  }
// }
//
//
// extension ChatMessageContentRecord {
//  init(from _: ChatMessageContentModel, chatMessageId _: String) {
//    fatalError()
////    self.init(
////      id: model.id,
////      chatMessageId: chatMessageId,
////      type: model.type,
////      text: model.text,
////      projectRoot: model.projectRoot,
////      isStreaming: model.isStreaming,
////      signature: model.signature,
////      reasoningDuration: model.reasoningDuration,
////      toolName: model.toolName,
////      toolInput: model.toolInput,
////      toolResult: model.toolResult,
////      createdAt: model.createdAt,
////      updatedAt: model.updatedAt)
//  }
// }
//
// extension ChatMessageRecord {
//  init(from _: ChatMessageModel, chatThreadId _: String) {
//    fatalError()
////    self.init(
////      id: model.id,
////      chatThreadId: chatThreadId,
////      role: model.role,
////      createdAt: model.createdAt,
////      updatedAt: model.updatedAt)
//  }
// }
//
// extension ChatEventRecord {
//  init(from _: ChatEventModel, chatThreadId _: String) {
//    fatalError()
////    self.init(
////      id: model.id,
////      chatThreadId: chatThreadId,
////      type: model.type,
////      chatMessageContentId: model.messageContent?.id,
////      checkpointId: model.checkpointId,
////      role: model.role,
////      failureReason: model.failureReason,
////      createdAt: model.createdAt,
////      orderIndex: model.orderIndex)
//  }
// }
//
// extension ChatThreadRecord {
//  init(from _: ChatThreadModel) {
//    fatalError()
////    self.init(
////      id: model.id,
////      name: model.name,
////      createdAt: model.createdAt,
////      updatedAt: model.updatedAt,
////      projectPath: model.projectPath,
////      projectRootPath: model.projectRootPath)
//  }
// }
