//
//  OnboardingCompletionView.swift
//  BookVocab
//
//  Final screen of onboarding - completion celebration.
//  Shows success message and launches into main app.
//

import SwiftUI

/// Completion screen - final step of onboarding
struct OnboardingCompletionView: View {
    
    // MARK: - Properties
    
    let displayName: String
    let isPremium: Bool
    var onFinish: () -> Void
    
    // MARK: - State
    
    @State private var hasAppeared: Bool = false
    @State private var showConfetti: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success animation
            successSection
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.8)
            
            Spacer(minLength: AppSpacing.xxxl)
            
            // Message
            messageSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer()
            
            // Start button
            startSection
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            
            Spacer(minLength: AppSpacing.xxxl)
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .overlay {
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.2)) {
                hasAppeared = true
            }
            
            // Show confetti after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showConfetti = true
                }
            }
            
            // Hide confetti after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
    }
    
    // MARK: - Success Section
    
    private var successSection: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(AppColors.success.opacity(0.2), lineWidth: 8)
                .frame(width: 140, height: 140)
            
            // Inner filled circle
            Circle()
                .fill(AppColors.success.opacity(0.15))
                .frame(width: 120, height: 120)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(AppColors.success)
        }
    }
    
    // MARK: - Message Section
    
    private var messageSection: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.sm) {
                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                
                Text(greetingMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Status card
            statusCard
        }
    }
    
    private var greetingMessage: String {
        let name = displayName.isEmpty ? "Reader" : displayName
        return "Welcome, \(name)! Your account is ready."
    }
    
    private var statusCard: some View {
        VStack(spacing: AppSpacing.md) {
            if isPremium {
                // Premium status
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.orange)
                    
                    Text("Premium Active")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                    
                    Text("• Free trial started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("Enjoy unlimited books, words, and all study modes!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                // Free tier status
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue)
                    
                    Text("Free Account")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                }
                
                Text("You can upgrade to Premium anytime in Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Start Section
    
    private var startSection: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: onFinish) {
                HStack {
                    Text("Start Reading")
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            
            // Tips
            VStack(spacing: AppSpacing.xs) {
                tipRow(icon: "1.circle.fill", text: "Add your first book")
                tipRow(icon: "2.circle.fill", text: "Save words as you read")
                tipRow(icon: "3.circle.fill", text: "Study to master them")
            }
            .padding(.top, AppSpacing.sm)
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.primary)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        
        particles = (0..<50).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3)
            
            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position = CGPoint(
                    x: particles[i].position.x + CGFloat.random(in: -50...50),
                    y: size.height + 50
                )
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview

#Preview {
    OnboardingCompletionView(
        displayName: "John",
        isPremium: true,
        onFinish: {}
    )
}
