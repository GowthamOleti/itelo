//
//  InfoView.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import SwiftUI

@available(iOS 26.0, *)
struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    var onScroll: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("itelo")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Powered by Apple's Foundation Model. Your conversations remain private and secure, processed entirely on-device.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // Features Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        FeatureRow(
                            icon: "lock.shield.fill",
                            title: "Privacy First",
                            description: "All conversations are processed on-device. No data is sent to the cloud."
                        )
                        
                        FeatureRow(
                            icon: "sparkles",
                            title: "Apple Intelligence",
                            description: "Powered by Apple's advanced Foundation Model for intelligent responses."
                        )
                        
                        FeatureRow(
                            icon: "photo.badge.plus",
                            title: "Image Generation",
                            description: "Create images using Image Playground integration."
                        )
                        
                        FeatureRow(
                            icon: "bell.fill",
                            title: "Smart Reminders",
                            description: "Set reminders and alarms directly from conversations."
                        )
                        
                        FeatureRow(
                            icon: "magnifyingglass",
                            title: "Spotlight Search",
                            description: "Search your conversations using iOS Spotlight."
                        )
                    }
                    
                    Divider()
                    
                    // Technical Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical Details")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            DetailRow(label: "Model", value: "Apple Foundation Model")
                            DetailRow(label: "Processing", value: "On-Device")
                            DetailRow(label: "Data Storage", value: "Local Only")
                            DetailRow(label: "Minimum iOS", value: "iOS 18.0")
                        }
                    }
                    
                    Divider()
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "paintbrush.pointed.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text("Designed by OG")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Version 1.0")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if value < -20 {
                    onScroll()
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Scroll Offset Preference Key
@available(iOS 26.0, *)
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - InfoView with Detent Management
@available(iOS 26.0, *)
struct InfoViewWithDetent: View {
    @State private var shouldExpand = false
    
    var body: some View {
        InfoView(onScroll: {
            if !shouldExpand {
                shouldExpand = true
            }
        })
        .presentationDetents(shouldExpand ? [.large] : [.medium, .large])
    }
}

// MARK: - Feature Row Component
@available(iOS 26.0, *)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Detail Row Component
@available(iOS 26.0, *)
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    InfoView(onScroll: {})
        .padding()
        .background(Color.black)
}
