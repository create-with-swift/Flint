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
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow
    @State private var isHovering = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(rotation))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo with animation
                VStack(spacing: 20) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotation / 4))
                        .shadow(color: .blue.opacity(0.5), radius: 20)
                    
                    Text("Flint")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Generate 3D models from text")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    
                    HStack(spacing: 8) {
                        Toggle(isOn: Binding(
                            get: { viewModel.isHighQuality },
                            set: { viewModel.isHighQuality = $0 }
                        )) {
                            HStack(spacing: 6) {
                                Text("High Quality")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Text("Beta")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, .pink],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            }
                        }
                        .toggleStyle(.switch)
                        .disabled(viewModel.isGenerating)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .padding(.bottom, 16)
                    .frame(width: 400)
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                // Input field with glassmorphism effect
                HStack(spacing: 16) {
                    TextField("Describe your 3D model...", text: $prompt, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        )
                        .lineLimit(3)
                        .disabled(viewModel.isGenerating)
                        .onSubmit {
                            Task {
                                await generateModel()
                            }
                        }
                        .frame(maxWidth: 500)
                    
                    Button {
                        Task {
                            await generateModel()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: .blue.opacity(0.5), radius: isHovering ? 20 : 10)
                                .scaleEffect(isHovering ? 1.1 : 1.0)
                            
                            if viewModel.isGenerating {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.3)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(prompt.isEmpty || viewModel.isGenerating)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovering = hovering
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func generateModel() async {
        await viewModel.sendPromptToServer(prompt: prompt)
        if viewModel.errorMessage == nil {
            prompt = ""
            // Open the newly generated model automatically
            if let latestModel = viewModel.generatedModels.first {
                openWindow(id: "model", value: latestModel.id.uuidString)
            }
        }
    }
}

#Preview {
    ContentView()
}
