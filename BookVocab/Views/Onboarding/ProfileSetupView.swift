//
//  ProfileSetupView.swift
//  BookVocab
//
//  Second screen of onboarding - profile setup.
//  Collects display name from user.
//

import SwiftUI

/// Profile setup screen - collects user's display name
struct ProfileSetupView: View {
    
    // MARK: - Bindings
    
    @Binding var displayName: String
    
    // MARK: - Properties
    
    var onContinue: () -> Void
    
    // MARK: - State
    
    @State private var hasAppeared: Bool = false
    @FocusState private var isNameFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            headerSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer(minLength: AppSpacing.xxxl)
            
            // Name input
            nameInputSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer()
            
            // Continue button
            continueSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer(minLength: AppSpacing.xxxl)
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.2)) {
                hasAppeared = true
            }
            
            // Auto-focus name field after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(AppColors.tanDark)
                    .frame(width: 100, height: 100)
                
                Text(avatarInitial)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                
                Text("This will be shown on your profile")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var avatarInitial: String {
        if let first = displayName.first, !displayName.isEmpty {
            return String(first).uppercased()
        }
        return "?"
    }
    
    // MARK: - Name Input Section
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Display Name")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            TextField("Enter your name", text: $displayName)
                .font(.title3)
                .fontWeight(.medium)
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(isNameFocused ? AppColors.primary : Color.clear, lineWidth: 2)
                )
                .focused($isNameFocused)
                .textContentType(.name)
                .autocorrectionDisabled()
            
            Text("You can change this later in Settings")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(AppColors.cardBackground.opacity(0.5))
        )
    }
    
    // MARK: - Continue Section
    
    private var continueSection: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: {
                isNameFocused = false
                onContinue()
            }) {
                HStack {
                    Text("Continue")
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            
            Button(action: {
                displayName = ""
                isNameFocused = false
                onContinue()
            }) {
                Text("Skip for now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupView(
        displayName: .constant("John"),
        onContinue: {}
    )
}
