//
//  SettingsView.swift
//  Deekseep
//
//  Created by Goge on 2025/4/11.
//

import SwiftUI
import Foundation

// Add enum for color scheme
enum AppColorScheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// Enum for settings sections
enum SettingsSection: String, CaseIterable, Identifiable {
    case api = "API Settings"
    case display = "Display Settings"
    case appearance = "Appearance"
    case tuning = "Model Tuning"
    case about = "About"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .api: return "key.fill"
        case .display: return "text.alignleft"
        case .appearance: return "paintpalette.fill"
        case .about: return "info.circle.fill"
        case .tuning: return "wrench.and.screwdriver.fill"
        }
    }
}

struct SettingsView: View {
    @AppStorage("exampleSettingToggle") private var exampleToggle = true
    @AppStorage("apiKey") private var apiKey = APIKeys.deepSeekAPIKey
    @AppStorage("useMarkdownRenderer") private var useMarkdownRenderer = false
    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme.dark.rawValue
    @AppStorage("modelTemperature") private var modelTemperature = 0.6
    @AppStorage("modelMaxTokens") private var modelMaxTokens = 4000
    @State private var selectedSection: SettingsSection = .api
    
    private var selectedColorScheme: AppColorScheme {
        AppColorScheme(rawValue: appColorScheme) ?? .dark
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Options")
                    .font(.headline)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(SettingsSection.allCases) { section in
                            HStack {
                                Image(systemName: section.icon)
                                    .frame(width: 20)
                                Text(section.rawValue)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedSection == section ? 
                                          Color(.systemGray).opacity(0.3) : 
                                          Color.clear)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSection = section
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(width: 190)
            .background(Color(.systemGray).opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedSection {
                    case .api:
                        ApiSettingsView(apiKey: $apiKey)
                    case .display:
                        DisplaySettingsView(useMarkdownRenderer: $useMarkdownRenderer)
                    case .appearance:
                        AppearanceSettingsView(
                            selectedColorScheme: Binding<AppColorScheme>(
                                get: { selectedColorScheme },
                                set: { appColorScheme = $0.rawValue }
                            )
                        )
                    case .about:
                        AboutView()
                    case .tuning:
                        TuningSettingsView(
                            modelTemperature: $modelTemperature,
                            modelMaxTokens: $modelMaxTokens
                        )
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 600, height: 450)
        .preferredColorScheme(selectedColorScheme.colorScheme)
    }
}

struct ApiSettingsView: View {
    @Binding var apiKey: String
    
    // Check if currently using the default key
    private var isUsingDefaultKey: Bool {
        return apiKey == APIKeys.deepSeekAPIKey
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("API Key")
                .font(.headline)
            
            HStack {
                if isUsingDefaultKey {
                    SecureField("Default", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                } else {
                    SecureField("", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                }
                
                Button("Reset") {
                    apiKey = APIKeys.deepSeekAPIKey
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .padding(.leading, 4)
            }
            
            if apiKey.isEmpty {
                Text("API key is required")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Text("Your DeepSeek API key. Keep this secret and secure.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct DisplaySettingsView: View {
    @Binding var useMarkdownRenderer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Display Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Rendering Options")
                .font(.headline)
            
            Toggle("Use Markdown Renderer", isOn: $useMarkdownRenderer)
                .help("Renders using MarkdownUI. Disable to use LaTeXSwiftUI for math.")
            
            Text("Markdown Renderer Helps AI to render in Markdown Style.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct AppearanceSettingsView: View {
    @Binding var selectedColorScheme: AppColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Color Scheme")
                .font(.headline)
                .padding(.bottom, 6)
            
            Picker("", selection: $selectedColorScheme) {
                ForEach(AppColorScheme.allCases) { scheme in
                    Text(scheme.rawValue).tag(scheme)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200, alignment: .leading)
            .padding(.leading, 0)
            
            Text("Change the color scheme of the APP.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("Version")
                    .fontWeight(.medium)
                Spacer()
                Text("1.0.0")
            }
            .padding(.bottom,10)
            
            Link("View GitHub",
                  destination: URL(string: "https://www.example.com/TOS.html")!)
            
            Divider()
            
            Text("Deekseep is a unofficial AI-Chat application powered by DeepSeek. It features LaTeX and Markdown rendering capabilities.")
                .foregroundColor(.gray)
        }
    }
}

struct TuningSettingsView: View {
    @Binding var modelTemperature: Double
    @Binding var modelMaxTokens: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Model Tuning")
                .font(.title2)
                .fontWeight(.bold)
            
            // Temperature Control
            VStack(alignment: .leading, spacing: 8) {
                Text("Temperature")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    Slider(value: $modelTemperature, in: 0.1...1.0, step: 0.1)
                        .frame(maxWidth: 250)
                    
                    Text(String(format: "%.1f", modelTemperature))
                        .monospacedDigit()
                        .frame(width: 40)
                }
                
                Text("Controls randomness. Lower values are more focused and deterministic.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            // Max Tokens Control
            VStack(alignment: .leading, spacing: 8) {
                Text("Max Tokens")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    Stepper(
                        value: $modelMaxTokens,
                        in: 1000...8000,
                        step: 500,
                        label: {
                            Text("\(modelMaxTokens)")
                                .monospacedDigit()
                                .frame(width: 80, alignment: .leading)
                        }
                    )
                    .frame(maxWidth: 120)
                }
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text("Limits the length of the response. Higher values allow longer outputs.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
