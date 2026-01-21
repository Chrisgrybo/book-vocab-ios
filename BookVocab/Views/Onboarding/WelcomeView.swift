//
//  WelcomeView.swift
//  BookVocab
//
//  First screen of the onboarding flow.
//  Displays app value proposition and gets user started.
//

import SwiftUI

/// Welcome screen - first step of onboarding
struct WelcomeView: View {
    
    // MARK: - Properties
    
    var onContinue: () -> Void
    
    // MARK: - State
    
    @State private var hasAppeared: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero illustration
            heroSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 30)
            
            Spacer()
            
            // Value proposition
            valueProposition
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer()
            
            // CTA button
            ctaSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer(minLength: AppSpacing.xxxl)
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // App icon / illustration
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.primary)
            }
            
            // App name
            VStack(spacing: AppSpacing.xs) {
                Text("Read & Recall")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(AppColors.primary)
                
                Text("Build Your Vocabulary")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Value Proposition
    
    private var valueProposition: some View {
        VStack(spacing: AppSpacing.lg) {
            featureRow(
                icon: "books.vertical.fill",
                title: "Track Your Reading",
                description: "Add books and collect words as you read"
            )
            
            featureRow(
                icon: "text.book.closed.fill",
                title: "Learn New Words",
                description: "Definitions, synonyms & examples auto-filled"
            )
            
            featureRow(
                icon: "brain.head.profile",
                title: "Study & Master",
                description: "Flashcards & quizzes to help you remember"
            )
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.tanDark)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: onContinue) {
                HStack {
                    Text("Get Started")
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            
            Text("Setup takes less than a minute")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(onContinue: {})
}
