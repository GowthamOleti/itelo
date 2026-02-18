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
            let horizontalInset: CGFloat = 24
            let iconSize = min(152, geometry.size.width * 0.34)

            ZStack {
                FluidBackground()

                VStack(spacing: 20) {
                    Spacer(minLength: max(20, geometry.safeAreaInsets.top + 8))

                    Image("OnboardingIcon")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 12) {
                        Text("itelo")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Private, on-device AI for everyday tasks.")
                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Chat naturally and explore ideas while your data stays on your device.")
                            .font(.system(size: 19, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .frame(maxWidth: 420, alignment: .center)
                    .padding(.horizontal, horizontalInset)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()

                    Button("Get Started", action: onGetStarted)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .tint(.blue)
                        .frame(maxWidth: 360)
                        .padding(.horizontal, horizontalInset)
                        .padding(.bottom, max(22, geometry.safeAreaInsets.bottom + 8))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                // Force true horizontal centering regardless of intermediate padding/frames.
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
