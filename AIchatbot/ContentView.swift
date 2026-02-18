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
            
            VStack(spacing: 28) {
                Spacer(minLength: 40)

                VStack(alignment: .leading, spacing: 18) {
                    Text("itelo")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Private, on-device AI for everyday tasks.")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Chat naturally, create reminders, and explore ideas while your data stays on your device.")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 26)
                .frame(maxWidth: 560, alignment: .leading)
                .glassEffect(Material.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 10) {
                    Button("Get Started", action: onGetStarted)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .tint(.blue)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
            .safeAreaPadding(.top, 24)
            .safeAreaPadding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
