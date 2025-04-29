//
//  ViewModel.swift
//  Flint
//
//  Created by Matteo Altobello on 29/04/25.
//

import SwiftUI

@Observable
class ViewModel {
    var modelURL: URL? = nil // Default model
    var errorMessage: String?
    
    func sendPromptToServer(prompt: String) async {
        guard let url = URL(string: "http://192.168.1.120:8000/run") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = PromptRequest(prompt: prompt)
        
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Server error"
                return
            }
            
            // Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            let decodedResponse = try JSONDecoder().decode(MCPResponse.self, from: data)
            print("Decoded Response \(decodedResponse.modelURL)")
            
            if let url = URL(string: decodedResponse.modelURL) {
                print("Constructed URL : \(url)")
                modelURL = url
                errorMessage = nil
            } else {
                errorMessage = "Invalid model URL"
            }
        } catch {
            errorMessage = "Failed to send prompt: \(error.localizedDescription)"
        }
    }

}
