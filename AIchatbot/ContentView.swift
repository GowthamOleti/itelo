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
        GeometryReader { geometry in
            let contentWidth = min(420, max(0, geometry.size.width - 48))

            ZStack(alignment: .center) {
                FluidBackground()
                    .allowsHitTesting(false)

                VStack(spacing: 36) {
                    VStack(spacing: 18) {
                        Image("OnboardingIcon")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 152, height: 152)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)

                        VStack(spacing: 10) {
                            Text("itelo")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)

                            Text("Private, on-device AI for everyday tasks.")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text("Chat naturally and explore ideas while your data stays on your device.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: 420)

                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .tint(.white)
                }
                .frame(width: contentWidth)
                // Hard-center the whole onboarding group in the screen's coordinate space.
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        // Center relative to the full screen, not the safe-area-adjusted content region.
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
