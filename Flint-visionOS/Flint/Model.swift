//
//  Untitled.swift
//  Flint
//
//  Created by Create with Swift on 29/04/25.
//

struct PromptRequest: Codable {
    let prompt: String
}

struct MCPResponse: Codable {
    let result: [ResultItem]
    let modelURL: String
    
    enum CodingKeys: String, CodingKey {
        case result
        case modelURL = "model_url"
    }
}

struct ResultItem: Codable {
    let text: String
    let type: String
    let index: Int
}
