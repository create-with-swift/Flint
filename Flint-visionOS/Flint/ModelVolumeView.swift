//
//  ModelVolumeView.swift
//  Flint
//
//  Created by Create with Swift on 16/11/25.
//

import SwiftUI
import RealityKit

struct ModelVolumeView: View {
    let model: GeneratedModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        GeometryReader3D { geometry in
            ZStack {
                // 3D Model Display with proper sizing to prevent cropping
                Model3D(url: model.url) { resolvedModel in
                    resolvedModel
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width * 0.9,
                               height: geometry.size.height * 0.9)
                        .frame(depth: geometry.size.depth * 0.9)
                } placeholder: {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(2)
                        Text("Loading...")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            
                // Floating close button in top-right
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismissWindow(id: "model", value: model.id.uuidString)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.8))
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                    Spacer()
                }
            }
        }
    }
}
