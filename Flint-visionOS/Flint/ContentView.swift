//
//  ContentView.swift
//  Flint
//
//  Created by Create with Swift on 29/04/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var prompt = ""
    @State private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            if let modelURL = viewModel.modelURL {
                Model3D(url: modelURL) { resolvedModel3D in
                    resolvedModel3D
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(1.5)
                } placeholder: {
                    ProgressView()
                }
            } else {
                ProgressView("Loading model...")
            }
            
            TextField("Enter your prompt", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Send to MCP") {
                viewModel.modelURL = nil
                Task {
                    await viewModel.sendPromptToServer(prompt: prompt)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
