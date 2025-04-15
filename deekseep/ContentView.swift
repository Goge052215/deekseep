//
//  ContentView.swift
//  deekseep
//
//  Created by Goge on 2025/4/11.
//

import SwiftUI
import WebKit
import LaTeXSwiftUI
import MarkdownUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    let content: String
}

struct ContentView: View {
    @State private var promptText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: "assistant", content: "Hi, how can I help you today?")
    ]
    @State private var isSending: Bool = false
    @State private var selectedModel: String = "DeekSeep-V3"
    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme.dark.rawValue
    private let deekseepService = DeekseepService()
    private let mySystemRule = "You are Deekseep, a helpful AI assistant. Keep your responses friendly and relatively brief. IMPORTANT: When writing equations or mathematical expressions, always use display math format with $$...$$ delimiters instead of inline math ($...$). Ensure there are NO spaces between the $$ delimiters and the mathematical content itself (e.g., use $$\\frac{a}{b}$$ NOT $$ \\frac{a}{b} $$). Do not add a period after the latex equation. Leave a line after every equation display. Also, do not use inline math also include \\(...\\)"
    private let availableModels = ["DeekSeep-V3", "DeekSeep-R1"]
    
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("**Deekseep**")
                    .font(.title2)
                
                Spacer()
                
                Button {
                    openWindow(id: "settings")
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top)
            .padding(.bottom, 5)

            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Spacer(minLength: geometry.size.height - 100)
                            ForEach(messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                        .onAppear {
                            if let lastMessage = messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: messages) {
                         if let lastMessage = messages.last {
                             withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                             }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                HStack {
                    Image(systemName: "cpu")
                        .imageScale(.medium)
                        .foregroundColor(Color(.labelColor))
                    
                    Menu {
                        ForEach(availableModels, id: \.self) { model in
                            Button(action: {
                                selectedModel = model
                            }) {
                                HStack {
                                    Text(model)
                                        .font(.system(.body, design: .rounded))
                                    
                                    if selectedModel == model {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedModel)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(Color(.labelColor))
                            
                            Image(systemName: "chevron.down")
                                .imageScale(.small)
                                .font(.caption)
                                .foregroundColor(Color(.labelColor))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray).opacity(0.2))
                        )
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .menuIndicator(.hidden)
                }
                .padding(.bottom, 4)
                .padding(.leading, 5)
                .frame(width: 200)
                
                Spacer()
            }
            .padding(.horizontal, 15)

            HStack(alignment: .center) {
                RepresentableTextView(text: $promptText)
                    .onSubmit(sendMessage)

                Button(action: sendMessage) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .imageScale(.large)
                        }
                        if isSending {
                            Text("Sending...")
                                .padding(.leading, 2)
                        }
                    }
                    .padding(.horizontal, 5)
                }
                .disabled(promptText.isEmpty || isSending)
                .buttonStyle(.plain)
                .frame(height: 30)
                .padding(.trailing, 5)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(height: 60)
        }
        .padding(10)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(AppColorScheme(rawValue: appColorScheme)?.colorScheme)
    }

    func sendMessage() {
        let currentPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentPrompt.isEmpty else { return }
        promptText = ""

        let userMessage = ChatMessage(role: "user", content: currentPrompt)
        messages.append(userMessage)

        isSending = true

        let apiMessages = messages.map { DeekseepService.Message(role: $0.role, content: $0.content) }

        Task {
            do {
                let responseContent = try await deekseepService.sendMessageToDeekseep(
                    model: selectedModel,
                    messages: apiMessages,
                    systemPrompt: mySystemRule
                )
                let assistantMessage = ChatMessage(role: "assistant", content: responseContent)
                DispatchQueue.main.async {
                    messages.append(assistantMessage)
                    isSending = false
                }
            } catch {
                let errorMessageContent = "Error: \(error.localizedDescription)"
                let errorMessage = ChatMessage(role: "assistant", content: errorMessageContent)
                DispatchQueue.main.async {
                    messages.append(errorMessage)
                    isSending = false
                }
            }
        }
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    @AppStorage("useMarkdownRenderer") private var useMarkdownRenderer = false
    @AppStorage("renderMathInMarkdown") private var renderMathInMarkdown = true
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            Group {
                if useMarkdownRenderer {
                    if renderMathInMarkdown {
                        let components = processMathContent(message.content)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(components, id: \.self) { component in
                                if component.hasPrefix("MATH:") {
                                    let mathContent = String(component.dropFirst(5))
                                    LaTeX(mathContent)
                                        .parsingMode(.onlyEquations)
                                        .unencoded()
                                        .errorMode(.error)
                                        .renderingStyle(.original)
                                        .blockMode(.blockViews)
                                        .foregroundColor(foregroundColor)
                                } else {
                                    Markdown(component)
                                        .markdownTextStyle {
                                            ForegroundColor(foregroundColor)
                                        }
                                }
                            }
                        }
                    } else {
                        Markdown(message.content)
                            .markdownTextStyle {
                                ForegroundColor(foregroundColor)
                            }
                    }
                } else {
                    LaTeX(message.content)
                        .font(.body)
                        .foregroundColor(foregroundColor)
                        .parsingMode(.onlyEquations)
                        .unencoded()
                        .errorMode(.error)
                        .renderingStyle(.original)
                        .blockMode(.blockViews)
                }
            }
            .modifier(MessageBubbleStyle(role: message.role))
            
            if message.role == "assistant" {
                Spacer()
            }
        }
    }
    
    private func processMathContent(_ content: String) -> [String] {
        var components: [String] = []
        var currentText = ""
        var i = 0
        
        let contentArray = Array(content)
        
        while i < contentArray.count {
            // Check for display math ($$...$$)
            if i + 1 < contentArray.count && contentArray[i] == "$" && contentArray[i + 1] == "$" {
                if !currentText.isEmpty {
                    components.append(currentText)
                    currentText = ""
                }
                
                if let (mathContent, newIndex) = extractMathContent(contentArray, startIndex: i + 2, displayMath: true) {
                    components.append("MATH:$$\(mathContent)$$")
                    i = newIndex
                } else {
                    currentText.append(contentArray[i])
                    i += 1
                }
            }
            else if contentArray[i] == "$" {
                if let (mathContent, newIndex) = extractMathContent(contentArray, startIndex: i + 1, displayMath: false) {
                    if !currentText.isEmpty {
                        components.append(currentText)
                        currentText = ""
                    }
                    components.append("MATH:$\(mathContent)$")
                    i = newIndex
                } else {
                    currentText.append(contentArray[i])
                    i += 1
                }
            }
            else {
                currentText.append(contentArray[i])
                i += 1
            }
        }
        
        if !currentText.isEmpty {
            components.append(currentText)
        }
        
        return components
    }
    
    private func extractMathContent(_ content: [Character], startIndex: Int, displayMath: Bool) -> (String, Int)? {
        let endDelimiter = displayMath ? ["$", "$"] : ["$"]
        let delimiterLength = endDelimiter.count
        
        var j = startIndex
        var mathChars: [Character] = []
        
        while j < content.count - (delimiterLength - 1) {
            let isDelimiter = !displayMath ? content[j] == "$" :
                              (content[j] == "$" && content[j + 1] == "$")
            
            if isDelimiter {
                return (String(mathChars), j + delimiterLength)
            }
            
            mathChars.append(content[j])
            j += 1
        }
        
        return nil
    }

    private var foregroundColor: Color {
        message.role == "user" ? .white : .primary
    }

    private var backgroundColor: Color {
        message.role == "user" ? Color.blue.opacity(0.7) : Color.gray.opacity(0.4)
    }
    
    private var alignment: Alignment {
        message.role == "user" ? .trailing : .leading
    }
}

struct MessageBubbleStyle: ViewModifier {
    let role: String
    
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 400, alignment: alignment)
    }

    private var backgroundColor: Color {
        role == "user" ? Color.blue.opacity(0.8) : Color.gray.opacity(0.2)
    }

    private var alignment: Alignment {
        role == "user" ? .trailing : .leading
    }
}

#Preview {
    ContentView()
}

// MARK: - Custom TextView Representable (macOS)

struct RepresentableTextView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        textView.delegate = context.coordinator
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = false
        
        textView.textContainerInset = NSSize(width: 5, height: 12)
        textView.textContainer?.lineFragmentPadding = 5

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor
        
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 8
        scrollView.layer?.masksToBounds = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        
        init(_ text: Binding<String>) {
            self.text = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.text.wrappedValue = textView.string
        }
    }
}

