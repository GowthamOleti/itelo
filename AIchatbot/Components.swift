//
//  Components.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import SwiftUI
import UIKit

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Fluid Background (Apple Intelligence Style)
struct FluidBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Orb 1
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.blue, .purple, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .offset(x: animate ? -100 : 100, y: animate ? -100 : 100)
                .blur(radius: 60)
                .opacity(0.5)
            
            // Orb 2
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.cyan, .indigo, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: animate ? 100 : -100, y: animate ? 100 : -100)
                .blur(radius: 60)
                .opacity(0.5)
            
            // Orb 3
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.pink, .orange, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? -50 : 50, y: animate ? 200 : -200)
                .blur(radius: 50)
                .opacity(0.4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Bubble
struct GlassBubble: View {
    var isUser: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(isUser ? Color.blue.opacity(0.4) : Color.white.opacity(0.05))
            .glassEffect(isUser ? .clear : .regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isUser ? 0.3 : 0.2),
                                .white.opacity(isUser ? 0.1 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isUser ? .blue.opacity(0.3) : .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Premium Typing Indicator with Particle Animation
struct PremiumTypingIndicator: View {
    @State private var phase: CGFloat = 0
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var offset: CGPoint
        var opacity: Double
        var size: CGFloat
        var color: Color
        var angle: Double
    }
    
    var body: some View {
        ZStack {
            // Particle effects - floating around (simplified for performance)
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.x, y: particle.offset.y)
            }
            
            // Main typing indicator dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 10)
                        .scaleEffect(phase == CGFloat(index) ? 1.4 : 0.9)
                        .opacity(phase == CGFloat(index) ? 1 : 0.5)
                        .shadow(color: .cyan.opacity(0.6), radius: phase == CGFloat(index) ? 6 : 2)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).repeatForever(autoreverses: true).delay(Double(index) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(width: 130, height: 50)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.cyan.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .cyan.opacity(0.3), radius: 12, x: 0, y: 5)
        .onAppear {
            phase = 2
            initializeParticles()
            startParticleAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func initializeParticles() {
        // Reduce particle count for better performance
        let colors: [Color] = [.cyan, .blue, .purple]
        particles = (0..<6).map { index in
            let angle = Double(index) * (2 * .pi / 6)
            let radius = 20.0
            
            return Particle(
                position: CGPoint(x: 65, y: 25), // Center
                offset: CGPoint(
                    x: cos(angle) * radius,
                    y: sin(angle) * radius
                ),
                opacity: 0.6,
                size: 5,
                color: colors[index % colors.count],
                angle: angle
            )
        }
    }
    
    private func startParticleAnimation() {
        // Use slower update rate to reduce CPU usage
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Update without animation to reduce overhead
            for i in particles.indices {
                // Rotate particles around center
                particles[i].angle += 0.03
                let radius = 20.0 // Fixed radius for better performance
                particles[i].offset.x = cos(particles[i].angle) * radius
                particles[i].offset.y = sin(particles[i].angle) * radius
                
                // Pulsing opacity
                particles[i].opacity = 0.5 + 0.3 * sin(particles[i].angle * 2)
            }
        }
    }
}

// MARK: - Loading Animation View
struct LoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Background
            FluidBackground()
            
            // Loading content
            VStack(spacing: 24) {
                // Animated logo/icon
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .blue.opacity(0.5), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                    
                    // Inner pulsing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.6), .blue.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    // Center dot
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: .cyan.opacity(0.8), radius: 8)
                }
                
                // App name
                Text("itelo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
            }
        }
        .onAppear {
            // Start rotation animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Start pulsing animation
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.2
                opacity = 1.0
            }
        }
    }
}
