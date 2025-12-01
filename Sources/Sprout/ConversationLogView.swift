import SwiftUI

struct ConversationLogView: View {
    @EnvironmentObject var voiceAssistant: VoiceAssistant
    @State private var selectedMessage: VoiceAssistant.ConversationMessage?
    @State private var showingDeleteAlert = false
    @State private var messageToDelete: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Conversation Log")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                
                if !voiceAssistant.conversationHistory.isEmpty {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete all conversations")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            if voiceAssistant.conversationHistory.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Text("📝")
                        .font(.system(size: 48))
                    Text("No conversations yet")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Start talking to see your conversation history here")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Conversation list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(voiceAssistant.conversationHistory.enumerated()), id: \.element.id) { index, message in
                            ConversationLogItem(
                                message: message,
                                index: index,
                                onDelete: {
                                    messageToDelete = index
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: 400, height: 500)
        .alert("Delete Conversation", isPresented: $showingDeleteAlert) {
            if let index = messageToDelete {
                Button("Delete", role: .destructive) {
                    voiceAssistant.deleteConversation(at: index)
                    messageToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    messageToDelete = nil
                }
            } else {
                Button("Delete All", role: .destructive) {
                    voiceAssistant.deleteAllConversations()
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if messageToDelete != nil {
                Text("Are you sure you want to delete this conversation?")
            } else {
                Text("Are you sure you want to delete all conversations? This cannot be undone.")
            }
        }
    }
}

struct ConversationLogItem: View {
    let message: VoiceAssistant.ConversationMessage
    let index: Int
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with timestamp and delete
            HStack {
                HStack(spacing: 6) {
                    if let emoji = message.emoji {
                        Text(emoji)
                            .font(.system(size: 14))
                    }
                    Text(message.isUser ? "You" : "Seedling!")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(message.isUser ? .blue : .green)
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete this message")
            }
            
            // Message text
            Text(message.text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            
            // Analysis (if available) - expandable
            if let analysis = message.analysis, !analysis.isEmpty {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("💭 Analysis")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded {
                    Text(analysis)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(12)
        .background(message.isUser ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(message.isUser ? Color.blue.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

