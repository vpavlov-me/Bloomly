import Content
import DesignSystem
import PhotosUI
import SwiftUI

public struct OnboardingView: View {
    @ObservedObject private var manager = OnboardingManager.shared
    @ObservedObject private var profileStore = BabyProfileStore.shared
    @ObservedObject private var container: DependencyContainer

    @State private var currentPage = 0

    public init(container: DependencyContainer) {
        self._container = ObservedObject(initialValue: container)
    }

    public var body: some View {
        TabView(selection: $currentPage) {
            WelcomeScreen(onContinue: nextPage)
                .tag(0)

            CreateProfileScreen(
                onContinue: { name, birthDate, photo in
                    _ = profileStore.createProfile(name: name, birthDate: birthDate, photo: photo)
                    container.analytics.track(AnalyticsEvent(
                        name: "onboarding_profile_created",
                        metadata: ["has_photo": "\(photo != nil)"]
                    ))
                    nextPage()
                }
            )
            .tag(1)

            NotificationPermissionScreen(
                notificationManager: container.notificationManager,
                onContinue: {
                    container.analytics.track(AnalyticsEvent(name: "onboarding_notifications_granted"))
                    nextPage()
                },
                onSkip: {
                    container.analytics.track(AnalyticsEvent(name: "onboarding_notifications_skipped"))
                    nextPage()
                }
            )
            .tag(2)

            DashboardIntroScreen(
                onComplete: {
                    manager.completeOnboarding()
                    container.analytics.track(AnalyticsEvent(name: "onboarding_completed"))
                }
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear {
            container.analytics.track(AnalyticsEvent(name: "onboarding_started"))
        }
    }

    private func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }
}

// MARK: - Welcome Screen

private struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: BabyTrackTheme.spacing.xl) {
            Spacer()

            // App Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BabyTrackTheme.palette.accent, BabyTrackTheme.palette.accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, BabyTrackTheme.spacing.lg)

            // Title
            Text(AppCopy.string(for: "onboarding.welcome.title"))
                .font(BabyTrackTheme.typography.largeTitle.font)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)

            // Subtitle
            Text(AppCopy.string(for: "onboarding.welcome.subtitle"))
                .font(BabyTrackTheme.typography.body.font)
                .multilineTextAlignment(.center)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
                .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Benefits
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.lg) {
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: AppCopy.string(for: "onboarding.welcome.benefit1.title"),
                    description: AppCopy.string(for: "onboarding.welcome.benefit1.description")
                )

                BenefitRow(
                    icon: "bell.badge",
                    title: AppCopy.string(for: "onboarding.welcome.benefit2.title"),
                    description: AppCopy.string(for: "onboarding.welcome.benefit2.description")
                )

                BenefitRow(
                    icon: "applewatch",
                    title: AppCopy.string(for: "onboarding.welcome.benefit3.title"),
                    description: AppCopy.string(for: "onboarding.welcome.benefit3.description")
                )
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Get Started Button
            PrimaryButton(
                accessibilityLabel: AppCopy.string(for: "onboarding.welcome.getStarted"),
                accessibilityHint: "Double tap to begin setup",
                action: onContinue
            ) {
                Text(AppCopy.string(for: "onboarding.welcome.getStarted"))
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)
            .padding(.bottom, BabyTrackTheme.spacing.xl)
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BabyTrackTheme.typography.headline.font)
                    .foregroundStyle(BabyTrackTheme.palette.primaryText)

                Text(description)
                    .font(BabyTrackTheme.typography.caption.font)
                    .foregroundStyle(BabyTrackTheme.palette.mutedText)
            }
        }
    }
}

// MARK: - Create Profile Screen

private struct CreateProfileScreen: View {
    let onContinue: (String, Date, UIImage?) -> Void

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showNameError = false

    var body: some View {
        VStack(spacing: BabyTrackTheme.spacing.xl) {
            // Header
            VStack(spacing: BabyTrackTheme.spacing.md) {
                Text(AppCopy.string(for: "onboarding.profile.title"))
                    .font(BabyTrackTheme.typography.title.font)
                    .fontWeight(.bold)
                    .foregroundStyle(BabyTrackTheme.palette.primaryText)

                Text(AppCopy.string(for: "onboarding.profile.subtitle"))
                    .font(BabyTrackTheme.typography.body.font)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BabyTrackTheme.palette.mutedText)
                    .padding(.horizontal, BabyTrackTheme.spacing.xl)
            }
            .padding(.top, BabyTrackTheme.spacing.xxl)

            Spacer()

            // Photo Picker
            VStack(spacing: BabyTrackTheme.spacing.md) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(BabyTrackTheme.palette.accent, lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(BabyTrackTheme.palette.accent.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(BabyTrackTheme.palette.accent)
                        )
                }

                Button {
                    showImagePicker = true
                } label: {
                    Label(
                        selectedImage == nil ? AppCopy.string(for: "onboarding.profile.addPhoto") : AppCopy.string(for: "onboarding.profile.changePhoto"),
                        systemImage: "camera.fill"
                    )
                    .font(BabyTrackTheme.typography.body.font)
                    .foregroundStyle(BabyTrackTheme.palette.accent)
                }
            }

            // Form Fields
            VStack(spacing: BabyTrackTheme.spacing.lg) {
                VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
                    Text(AppCopy.string(for: "profile.name"))
                        .font(BabyTrackTheme.typography.caption.font)
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)

                    TextField(AppCopy.string(for: "profile.name.placeholder"), text: $name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: name) { _, _ in
                            showNameError = false
                        }

                    if showNameError {
                        Text(AppCopy.string(for: "onboarding.profile.nameError"))
                            .font(BabyTrackTheme.typography.caption.font)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.sm) {
                    Text(AppCopy.string(for: "profile.birthDate"))
                        .font(BabyTrackTheme.typography.caption.font)
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)

                    DatePicker(
                        "",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Continue Button
            PrimaryButton(
                accessibilityLabel: AppCopy.Common.save,
                accessibilityHint: "Double tap to save profile",
                action: handleContinue
            ) {
                Text(AppCopy.Common.save)
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)
            .padding(.bottom, BabyTrackTheme.spacing.xl)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
                .ignoresSafeArea()
        }
    }

    private func handleContinue() {
        // Validate name (2-50 characters)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 && trimmedName.count <= 50 else {
            showNameError = true
            return
        }

        onContinue(trimmedName, birthDate, selectedImage)
    }
}

// MARK: - Notification Permission Screen

private struct NotificationPermissionScreen: View {
    @ObservedObject var notificationManager: NotificationManager
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: BabyTrackTheme.spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .padding(.bottom, BabyTrackTheme.spacing.lg)

            // Title
            Text(AppCopy.string(for: "onboarding.notifications.title"))
                .font(BabyTrackTheme.typography.title.font)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)

            // Subtitle
            Text(AppCopy.string(for: "onboarding.notifications.subtitle"))
                .font(BabyTrackTheme.typography.body.font)
                .multilineTextAlignment(.center)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
                .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Benefits
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.lg) {
                NotificationBenefitRow(
                    icon: "clock.fill",
                    text: AppCopy.string(for: "onboarding.notifications.benefit1")
                )

                NotificationBenefitRow(
                    icon: "moon.fill",
                    text: AppCopy.string(for: "onboarding.notifications.benefit2")
                )

                NotificationBenefitRow(
                    icon: "bell.slash.fill",
                    text: AppCopy.string(for: "onboarding.notifications.benefit3")
                )
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Buttons
            VStack(spacing: BabyTrackTheme.spacing.md) {
                PrimaryButton(
                    accessibilityLabel: AppCopy.string(for: "onboarding.notifications.enable"),
                    accessibilityHint: "Double tap to enable notifications",
                    action: {
                        Task {
                            await notificationManager.requestNotificationPermission()
                            onContinue()
                        }
                    }
                ) {
                    Text(AppCopy.string(for: "onboarding.notifications.enable"))
                }

                Button {
                    onSkip()
                } label: {
                    Text(AppCopy.string(for: "onboarding.notifications.skip"))
                        .font(BabyTrackTheme.typography.body.font)
                        .foregroundStyle(BabyTrackTheme.palette.mutedText)
                }
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)
            .padding(.bottom, BabyTrackTheme.spacing.xl)
        }
    }
}

// MARK: - Notification Benefit Row

private struct NotificationBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .frame(width: 32)

            Text(text)
                .font(BabyTrackTheme.typography.body.font)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)

            Spacer()
        }
    }
}

// MARK: - Dashboard Intro Screen

private struct DashboardIntroScreen: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: BabyTrackTheme.spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .padding(.bottom, BabyTrackTheme.spacing.lg)

            // Title
            Text(AppCopy.string(for: "onboarding.intro.title"))
                .font(BabyTrackTheme.typography.largeTitle.font)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(BabyTrackTheme.palette.primaryText)

            // Subtitle
            Text(AppCopy.string(for: "onboarding.intro.subtitle"))
                .font(BabyTrackTheme.typography.body.font)
                .multilineTextAlignment(.center)
                .foregroundStyle(BabyTrackTheme.palette.mutedText)
                .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Features
            VStack(alignment: .leading, spacing: BabyTrackTheme.spacing.lg) {
                FeatureRow(
                    icon: "list.bullet.clipboard",
                    title: AppCopy.string(for: "onboarding.intro.feature1.title"),
                    description: AppCopy.string(for: "onboarding.intro.feature1.description")
                )

                FeatureRow(
                    icon: "ruler",
                    title: AppCopy.string(for: "onboarding.intro.feature2.title"),
                    description: AppCopy.string(for: "onboarding.intro.feature2.description")
                )

                FeatureRow(
                    icon: "gear",
                    title: AppCopy.string(for: "onboarding.intro.feature3.title"),
                    description: AppCopy.string(for: "onboarding.intro.feature3.description")
                )
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)

            Spacer()

            // Get Started Button
            PrimaryButton(
                accessibilityLabel: AppCopy.string(for: "onboarding.intro.getStarted"),
                accessibilityHint: "Double tap to start using the app",
                action: onComplete
            ) {
                Text(AppCopy.string(for: "onboarding.intro.getStarted"))
            }
            .padding(.horizontal, BabyTrackTheme.spacing.xl)
            .padding(.bottom, BabyTrackTheme.spacing.xl)
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: BabyTrackTheme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(BabyTrackTheme.palette.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BabyTrackTheme.typography.headline.font)
                    .foregroundStyle(BabyTrackTheme.palette.primaryText)

                Text(description)
                    .font(BabyTrackTheme.typography.caption.font)
                    .foregroundStyle(BabyTrackTheme.palette.mutedText)
            }
        }
    }
}

// MARK: - Image Picker

private struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
