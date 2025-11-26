//
//  Model.swift
//  Flint
//
//  Created by Create with Swift on 29/04/25.
//

import Foundation

struct PromptRequest: Codable {
    let prompt: String
}

struct MCPResponse: Codable {
    let success: Bool
    let modelURL: String
    let model: String
    let `protocol`: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case success
        case modelURL = "model_url"
        case model
        case `protocol`
        case size
    }
}

struct GeneratedModel: Identifiable, Hashable {
    let id: UUID
    let prompt: String
    let url: URL
    let createdAt: Date
    
    init(id: UUID = UUID(), prompt: String, url: URL, createdAt: Date = Date()) {
        self.id = id
        self.prompt = prompt
        self.url = url
        self.createdAt = createdAt
    }
}
