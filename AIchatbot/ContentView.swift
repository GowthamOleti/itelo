//
//  ContentView.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                ChatView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        hasSeenOnboarding = true
                    }
                }
                    .transition(.opacity)
            }
        }
    }
}

private struct OnboardingView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        ZStack {
            FluidBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 14) {
                    Text("itelo")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Your private, on-device AI companion for chat, reminders, and image ideas.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .glassEffect(Material.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .glassEffect(Material.regular, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .padding(.top, 30)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
