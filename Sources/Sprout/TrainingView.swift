import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var name = ""
    @State private var gender = ""
    @State private var age = ""
    @State private var mentalHealth = ""
    
    let questions = [
        ("What is your name?", "name"),
        ("Are you a boy or a girl?", "gender"),
        ("Are you young or elderly?", "age"),
        ("Do you have any mental health concerns or conditions you'd like me to be aware of? (This helps me provide better support)", "mentalHealth")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🌱 Training")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            ScrollView {
                VStack(spacing: 30) {
                    // Progress indicator
                    ProgressView(value: Double(currentStep), total: Double(questions.count))
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    if currentStep < questions.count {
                        // Current question
                        VStack(spacing: 20) {
                            Text(questions[currentStep].0)
                                .font(.system(size: 24, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            // Answer input based on question type
                            if questions[currentStep].1 == "name" {
                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 18))
                                    .padding(.horizontal, 40)
                                    .onSubmit {
                                        nextStep()
                                    }
                            } else if questions[currentStep].1 == "gender" {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        gender = "boy"
                                        nextStep()
                                    }) {
                                        VStack(spacing: 8) {
                                            Text("👦")
                                                .font(.system(size: 48))
                                            Text("Boy")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(gender == "boy" ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        gender = "girl"
                                        nextStep()
                                    }) {
                                        VStack(spacing: 8) {
                                            Text("👧")
                                                .font(.system(size: 48))
                                            Text("Girl")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(gender == "girl" ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        gender = "other"
                                        nextStep()
                                    }) {
                                        VStack(spacing: 8) {
                                            Text("🌈")
                                                .font(.system(size: 48))
                                            Text("Other")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(gender == "other" ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 40)
                            } else if questions[currentStep].1 == "age" {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        age = "young"
                                        nextStep()
                                    }) {
                                        VStack(spacing: 8) {
                                            Text("🌱")
                                                .font(.system(size: 48))
                                            Text("Young")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(age == "young" ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        age = "elderly"
                                        nextStep()
                                    }) {
                                        VStack(spacing: 8) {
                                            Text("🌳")
                                                .font(.system(size: 48))
                                            Text("Elderly")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(age == "elderly" ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 40)
                            } else if questions[currentStep].1 == "mentalHealth" {
                                TextEditor(text: $mentalHealth)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 40)
                                
                                Text("This information helps Sprout provide better, more personalized support. It's kept private and only used locally.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            
                            // Next button
                            if questions[currentStep].1 != "gender" && questions[currentStep].1 != "age" {
                                Button(action: nextStep) {
                                    HStack {
                                        Text(currentStep == questions.count - 1 ? "Complete Training" : "Next")
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        canProceed() ? Color.accentColor : Color.secondary.opacity(0.3)
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!canProceed())
                                .padding(.horizontal, 40)
                                .padding(.top, 10)
                            }
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Completion screen
                        VStack(spacing: 30) {
                            Text("✅ Training Complete!")
                                .font(.system(size: 28, weight: .bold))
                            
                            Text("Sprout is now personalized for you!")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            
                            // Summary
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Profile:")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                InfoRow(label: "Name", value: name.isEmpty ? "Not set" : name)
                                InfoRow(label: "Gender", value: gender.isEmpty ? "Not set" : gender.capitalized)
                                InfoRow(label: "Age", value: age.isEmpty ? "Not set" : age.capitalized)
                                
                                if !mentalHealth.isEmpty {
                                    InfoRow(label: "Mental Health Info", value: mentalHealth)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                            
                            Button(action: completeTraining) {
                                Text("Save & Finish")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 40)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 600, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func canProceed() -> Bool {
        switch questions[currentStep].1 {
        case "name":
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case "mentalHealth":
            return true // Optional field
        default:
            return true
        }
    }
    
    private func nextStep() {
        withAnimation {
            if currentStep < questions.count - 1 {
                currentStep += 1
            }
        }
    }
    
    private func completeTraining() {
        settings.saveTrainingData(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: gender,
            age: age,
            mentalHealth: mentalHealth.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dismiss()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
        }
    }
}

