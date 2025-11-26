//
//  ViewModel.swift
//  Flint
//
//  Created by Create with Swift on 29/04/25.
//

import SwiftUI

@Observable
class ViewModel {
    var generatedModels: [GeneratedModel] = []
    var isGenerating: Bool = false
    var errorMessage: String?
    var isHighQuality: Bool = false
    
    func sendPromptToServer(prompt: String) async {
        let endpoint = isHighQuality ? "http://localhost:8000/run-high" : "http://localhost:8000/run"
        guard let url = URL(string: endpoint) else {
            errorMessage = "Invalid URL"
            isGenerating = false
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = .infinity
        
        let body = PromptRequest(prompt: prompt)
        
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Server error"
                isGenerating = false
                return
            }
            
            // Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            let decodedResponse = try JSONDecoder().decode(MCPResponse.self, from: data)
            print("Decoded Response \(decodedResponse.modelURL)")
            
            if let modelURL = URL(string: "http://localhost:8000\(decodedResponse.modelURL)") {
                print("Constructed URL : \(modelURL)")
                
                // Add new model to the history
                let newModel = GeneratedModel(prompt: prompt, url: modelURL)
                generatedModels.insert(newModel, at: 0)
                
                errorMessage = nil
            } else {
                errorMessage = "Invalid model URL"
            }
            
            isGenerating = false
        } catch {
            errorMessage = "Failed to send prompt: \(error.localizedDescription)"
            isGenerating = false
        }
    }
    
    func deleteModel(_ model: GeneratedModel) {
        generatedModels.removeAll { $0.id == model.id }
    }
}
