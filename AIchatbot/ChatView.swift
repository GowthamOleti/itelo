//
//  ChatView.swift
//  AIchatbot
//
//  Created by Gowtham Oleti on 01/12/25.
//

import SwiftUI
import ImagePlayground
import SwiftData
import class UIKit.UIImage
import class UIKit.UIDevice
import class UIKit.UIScreen

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.createdAt, order: .reverse) private var sessions: [ChatSession]
    @State private var viewModel = ChatViewModel()
    @State private var selectedSession: ChatSession?
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @State private var showNewChat = false
    @State private var hasInitialized = false
    @State private var showHistorySheet = false

    private var sortedSessions: [ChatSession] {
        sessions.sorted { lhs, rhs in
            let lhsDate = latestActivityDate(for: lhs)
            let rhsDate = latestActivityDate(for: rhs)

            if lhsDate == rhsDate {
                return lhs.createdAt > rhs.createdAt
            }

            return lhsDate > rhsDate
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedSession) {
                ForEach(sortedSessions) { session in
                    NavigationLink(value: session) {
                        VStack(alignment: .leading) {
                            Text(session.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text(latestActivityDate(for: session).formatted(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            modelContext.delete(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .defaultScrollAnchor(.top)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .contentMargins(.top, 0, for: .scrollContent)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNewChat) {
                        Label("New Chat", systemImage: "square.and.pencil")
                    }
                }
            }
        } detail: {
            if let session = selectedSession {
                ChatInterface(viewModel: viewModel, onShowHistory: {
                    // Show history sheet on iPhone, toggle sidebar on iPad
                    #if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        showHistorySheet = true
                    } else {
                        withAnimation {
                            columnVisibility = .all
                        }
                    }
                    #else
                    withAnimation {
                        columnVisibility = .all
                    }
                    #endif
                })
                    .id(session.id) // Force refresh when session changes
                    .onAppear {
                        viewModel.setContext(modelContext)
                        viewModel.loadSession(session)
                    }
                    .onChange(of: session) { _, newSession in
                        viewModel.loadSession(newSession)
                    }
            } else {
                ContentUnavailableView("Select a Chat", systemImage: "message")
            }
        }
        .onAppear {
            // Initialize: create a new session if none exists or select the first one
                if !hasInitialized {
                    if sessions.isEmpty {
                        // Create a new chat session
                        let newSession = ChatSession()
                        modelContext.insert(newSession)
                        selectedSession = newSession
                    } else if selectedSession == nil {
                        // Select the most recently active session
                        selectedSession = sortedSessions.first
                    }
                    hasInitialized = true
                }
        }
        .onChange(of: selectedSession) { oldValue, newValue in
            // When a session is selected, hide sidebar on iPhone (keep visible on iPad)
            if newValue != nil {
                #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    withAnimation {
                        columnVisibility = .detailOnly
                    }
                }
                #endif
            }
        }
        .onChange(of: sessions.count) { oldCount, newCount in
            // If all sessions were deleted, create a new one
            if newCount == 0 && selectedSession == nil {
                let newSession = ChatSession()
                modelContext.insert(newSession)
                selectedSession = newSession
            }
        }
        .sheet(isPresented: $showHistorySheet) {
            if #available(iOS 26.0, *) {
                HistoryListView(
                    sessions: sortedSessions,
                    selectedSession: $selectedSession,
                    onDismiss: { showHistorySheet = false },
                    onCreateNew: createNewChat
                )
                .presentationDetents([.medium, .large])
            } else {
                // Fallback for older iOS versions
                NavigationStack {
                    List {
                        ForEach(sortedSessions) { session in
                            Button(action: {
                                selectedSession = session
                                showHistorySheet = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(latestActivityDate(for: session).formatted(date: .numeric, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(session)
                                    if selectedSession?.id == session.id {
                                        selectedSession = sortedSessions.first(where: { $0.id != session.id })
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .defaultScrollAnchor(.top)
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    .contentMargins(.top, 0, for: .scrollContent)
                    .navigationTitle("History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                createNewChat()
                            }) {
                                Label("New Chat", systemImage: "square.and.pencil")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func createNewChat() {
        let newSession = ChatSession()
        modelContext.insert(newSession)
        selectedSession = newSession
        showHistorySheet = false
    }

    private func latestActivityDate(for session: ChatSession) -> Date {
        session.messages.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? session.createdAt
    }
}

// MARK: - History List View (for Sheet)
@available(iOS 26.0, *)
struct HistoryListView: View {
    let sessions: [ChatSession]
    @Binding var selectedSession: ChatSession?
    let onDismiss: () -> Void
    let onCreateNew: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: {
                    onCreateNew()
                    dismiss()
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // History list - text directly on system bottom sheet, no background
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sessions) { session in
                        Button(action: {
                            selectedSession = session
                            onDismiss()
                            dismiss()
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    
                                    Text(
                                        (session.messages.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? session.createdAt)
                                            .formatted(date: .numeric, time: .shortened)
                                    )
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                modelContext.delete(session)
                                if selectedSession?.id == session.id {
                                    selectedSession = sessions.first(where: { $0.id != session.id })
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                        if session.id != sessions.last?.id {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.top)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .contentMargins(.top, 0, for: .scrollContent)
        }
    }
}

struct ChatInterface: View {
    @Bindable var viewModel: ChatViewModel
    var onShowHistory: () -> Void
    @FocusState private var isFocused: Bool
    @State private var showImagePlayground = false
    @State private var showInfo = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
            ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isThinking {
                        HStack {
                                PremiumTypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .transition(.opacity)
                            .id("thinking")
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .overlay {
                    if viewModel.messages.isEmpty {
                        GreetingView()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.messages.count) {
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                        // Haptic feedback for new message
                        HapticManager.shared.impact(style: .light)
                    }
                }
                .onChange(of: viewModel.isThinking) {
                    if viewModel.isThinking {
                        withAnimation {
                            proxy.scrollTo("thinking", anchor: .bottom)
                        }
                        // Haptic feedback for thinking start
                        HapticManager.shared.impact(style: .soft)
                    }
                }
                .onChange(of: viewModel.shouldTriggerImagePlayground) {
                    if viewModel.shouldTriggerImagePlayground {
                        showImagePlayground = true
                        viewModel.shouldTriggerImagePlayground = false // Reset flag
                    }
                }
            }
            .defaultScrollAnchor(.top)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .contentMargins(.top, 0, for: .scrollContent)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    // Conversation Starters
                    if viewModel.messages.isEmpty {
                        ConversationStartersView { starter in
                            viewModel.inputText = starter
                            sendMessageWithHaptics()
                        }
                    }
                    
                    // New polished text input design
                    HStack(spacing: 12) {
                        // Image button
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            showImagePlayground = true
                        }) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .glassEffect(Material.regular, in: Circle())
                        }
                        
                        // Text input container
                        TextField("Ask anything...", text: $viewModel.inputText)
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .regular))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .lineLimit(1)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .frame(minHeight: 50)
                            .glassEffect(Material.regular, in: Capsule())
                            .focused($isFocused)
                            .submitLabel(.send)
                            .onSubmit {
                                if !viewModel.inputText.isEmpty {
                                    sendMessageWithHaptics()
                                }
                            }
                        
                        // Send button
                        Button(action: {
                            sendMessageWithHaptics()
                        }) {
                            Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassEffect(Material.regular, in: Circle())
                        }
                        .disabled(viewModel.inputText.isEmpty)
                        .opacity(viewModel.inputText.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                Text("All content is generated securely on-device. No data is sent to the cloud.")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 4)
            }
            .animation(nil, value: isFocused)
        }
        .background {
            FluidBackground()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    onShowHistory()
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("itelo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .gray],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            if #available(iOS 26.0, *) {
                InfoViewWithDetent()
            }
        }
        .imagePlaygroundSheet(isPresented: $showImagePlayground, concept: viewModel.imagePrompt) { url in
                if let data = try? Data(contentsOf: url) {
                    // Add bot's image response
                    if let session = viewModel.currentSession {
                        let botMessage = ChatMessage(text: "Here's your image!", isUser: false, imageData: data)
                        botMessage.session = session
                        session.messages.append(botMessage)
                        viewModel.messages.append(botMessage)
                    }
                    
                    // Clear the prompt
                    viewModel.imagePrompt = ""
                }
            }

        .preferredColorScheme(.dark)
    }
    
    private func sendMessageWithHaptics() {
        HapticManager.shared.impact(style: .medium)
        viewModel.sendMessage()
    }
}

struct GreetingView: View {
    @State private var userName: String = "there"
    @State private var greeting: String = "Good morning"
    @State private var glowIntensity: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Hi \(userName).")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.6), radius: glowIntensity, x: 0, y: 0)
                .shadow(color: .cyan.opacity(0.4), radius: glowIntensity * 1.5, x: 0, y: 0)
            
            Text(greeting)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .shadow(color: .white.opacity(0.4), radius: glowIntensity * 0.8, x: 0, y: 0)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 24)
        .background(Color.clear)
        .onAppear {
            updateGreeting()
            // Start glow animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 8
            }
        }
    }
    
    private func updateGreeting() {
        // Get Name
        let deviceName = UIDevice.current.name
        var name = "there"
        
        if let extracted = deviceName.split(separator: "’").first { // "Gowtham’s iPhone" -> "Gowtham"
            name = String(extracted)
        } else if let extracted = deviceName.split(separator: "'").first {
             name = String(extracted)
        }
        
        // If the name is just "iPhone", fallback to "there"
        if name == "iPhone" {
            userName = "there"
        } else {
            userName = name
        }
        
        // Get Time
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<22: greeting = "Good evening"
        default: greeting = "Good late night"
        }
    }
}

struct ConversationStartersView: View {
    let onSelect: (String) -> Void
    
    let starters = [
        ("Write a birthday note for my best friend", "🎂"),
        ("Remind me to call mom at 5pm", "📞"),
        ("Generate an image of a cozy coffee shop", "☕"),
        ("What's a good recipe for dinner tonight?", "🍝")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(starters.enumerated()), id: \.offset) { index, starter in
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        onSelect(starter.0)
                    }) {
                        HStack(spacing: 8) {
                            Text(starter.1)
                                .font(.system(size: 16))
                            
                            Text(starter.0)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(Material.regular, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }
}

struct AnimatedRow: View {
    let items: [String]
    let direction: ScrollDirection
    let onSelect: (String) -> Void
    
    @State private var offset: CGFloat = 0
    
    enum ScrollDirection {
        case left, right
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Triple the items for seamless loop
                    ForEach(0..<3) { iteration in
                        ForEach(items.indices, id: \.self) { index in
                            let item = items[index]
                            Button(action: {
                                HapticManager.shared.impact(style: .light)
                                onSelect(item)
                            }) {
                                Text(item)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .glassEffect(Material.regular, in: Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .offset(x: offset)
            }
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .disabled(false) // Always allow interaction
            .onAppear {
                startAnimation()
            }
        }
        .frame(height: 44)
    }
    
    private func startAnimation() {
        let itemWidth: CGFloat = 200
        let totalWidth = itemWidth * CGFloat(items.count)
        
        if direction == .right {
            withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) {
                offset = -totalWidth
            }
        } else {
            offset = -totalWidth
            withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) {
                offset = 0
            }
        }
    }
}

struct StarterButton: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(Material.regular, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Text(.init(message.text)) // Enable Markdown
                        .padding(14)
                        .foregroundStyle(.white)
                        .background(GlassBubble(isUser: true))
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Text(.init(message.text)) // Enable Markdown
                        .padding(14)
                        .foregroundStyle(.white)
                        .textSelection(.enabled) // Allow text selection
                        .background(GlassBubble(isUser: false))
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity).animation(.bouncy),
            removal: .opacity
        ))
    }
}

#Preview {
    ChatView()
        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
}
