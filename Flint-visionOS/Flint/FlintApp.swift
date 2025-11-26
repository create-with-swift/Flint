//
//  FlintApp.swift
//  Flint
//
//  Created by Create with Swift on 29/04/25.
//

import SwiftUI

@main
struct FlintApp: App {
    @State private var viewModel = ViewModel()
    
    var body: some Scene {
        // Main control window - plain style for UI
        WindowGroup(id: "main") {
            ContentView()
                .environment(viewModel)
        }
        
        // Dynamic volumetric windows for each model
        WindowGroup(id: "model", for: String.self) { $modelId in
            if let modelId = modelId,
               let uuid = UUID(uuidString: modelId),
               let model = viewModel.generatedModels.first(where: { $0.id == uuid }) {
                ModelVolumeView(model: model)
            } else {
                VStack {
                    Text("Model not found")
                        .font(.headline)
                    Text("This model may have been deleted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 400, height: 400, depth: 400)
        .windowResizability(.contentMinSize)
    }
}
