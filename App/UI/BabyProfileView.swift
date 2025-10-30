import Content
import DesignSystem
import PhotosUI
import SwiftUI
import Tracking

public struct BabyProfileView: View {
    @ObservedObject private var profileStore = BabyProfileStore.shared
    @ObservedObject private var container: DependencyContainer

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var totalEventsCount: Int = 0
    @State private var isLoadingStats = false

    public init(container: DependencyContainer) {
        self._container = ObservedObject(initialValue: container)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: BloomyTheme.spacing.xl) {
                if let profile = profileStore.currentProfile {
                    // MARK: - Profile Header
                    VStack(spacing: BloomyTheme.spacing.lg) {
                        // Photo
                        ZStack(alignment: .bottomTrailing) {
                            if let photo = profile.photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(BloomyTheme.palette.accent, lineWidth: 3)
                                    )
                            } else {
                                Circle()
                                    .fill(BloomyTheme.palette.accent.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(BloomyTheme.palette.accent)
                                    )
                            }

                            Button {
                                showImagePicker = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(BloomyTheme.palette.accent)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, BloomyTheme.spacing.xl)

                        // Name
                        Text(profile.name)
                            .font(BloomyTheme.typography.title.font)
                            .foregroundStyle(BloomyTheme.palette.primaryText)

                        // Age
                        Text(profile.ageText)
                            .font(BloomyTheme.typography.body.font)
                            .foregroundStyle(BloomyTheme.palette.mutedText)
                    }

                    // MARK: - Profile Info
                    VStack(spacing: BloomyTheme.spacing.md) {
                        InfoRow(
                            icon: "calendar",
                            label: AppCopy.string(for: "profile.birthDate"),
                            value: formatDate(profile.birthDate)
                        )

                        InfoRow(
                            icon: "clock",
                            label: AppCopy.string(for: "profile.age.exact"),
                            value: exactAge(profile)
                        )

                        if isLoadingStats {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, BloomyTheme.spacing.sm)
                                Text(AppCopy.Common.loading)
                                    .font(BloomyTheme.typography.caption.font)
                            }
                        } else {
                            InfoRow(
                                icon: "chart.bar",
                                label: AppCopy.string(for: "profile.totalEvents"),
                                value: "\(totalEventsCount)"
                            )
                        }
                    }
                    .padding(.horizontal, BloomyTheme.spacing.lg)

                    // MARK: - Actions
                    VStack(spacing: BloomyTheme.spacing.md) {
                        PrimaryButton(
                            accessibilityLabel: AppCopy.string(for: "profile.edit"),
                            accessibilityHint: "Double tap to edit profile",
                            action: {
                                showEditSheet = true
                                container.analytics.track(AnalyticsEvent(name: "profile_edit_tapped"))
                            }
                        ) {
                            Label(AppCopy.string(for: "profile.edit"), systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(AppCopy.string(for: "profile.delete"), systemImage: "trash")
                                .font(BloomyTheme.typography.body.font)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, BloomyTheme.spacing.lg)
                    .padding(.top, BloomyTheme.spacing.lg)
                } else {
                    // MARK: - No Profile State
                    EmptyStateView(
                        icon: "person.crop.circle",
                        title: AppCopy.string(for: "profile.empty.title"),
                        message: AppCopy.string(for: "profile.empty.message"),
                        actionTitle: AppCopy.string(for: "profile.create")
                    ) {
                        showEditSheet = true
                    }
                }

                Spacer(minLength: BloomyTheme.spacing.xl)
            }
        }
        .navigationTitle(Text(AppCopy.string(for: "profile.title")))
        .sheet(isPresented: $showEditSheet) {
            if let profile = profileStore.currentProfile {
                EditProfileView(
                    profile: profile,
                    onSave: { name, photo in
                        profileStore.updateProfile(name: name, photo: photo)
                        container.analytics.track(AnalyticsEvent(name: "profile_edited"))
                    }
                )
            } else {
                CreateProfileView(
                    onCreate: { name, birthDate, photo in
                        _ = profileStore.createProfile(name: name, birthDate: birthDate, photo: photo)
                        container.analytics.track(AnalyticsEvent(name: "profile_created"))
                    }
                )
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
                .ignoresSafeArea()
        }
        .alert(AppCopy.string(for: "profile.delete.title"), isPresented: $showDeleteConfirmation) {
            Button(AppCopy.string(for: "profile.delete.confirm"), role: .destructive) {
                profileStore.deleteProfile()
                container.analytics.track(AnalyticsEvent(name: "profile_deleted"))
            }
            Button(AppCopy.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppCopy.string(for: "profile.delete.message"))
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                profileStore.updateProfile(photo: image)
                container.analytics.track(AnalyticsEvent(name: "photo_changed"))
                selectedImage = nil
            }
        }
        .task {
            container.analytics.track(AnalyticsEvent(name: "profile_viewed"))
            await loadStatistics()
        }
    }

    // MARK: - Helper Views

    private struct InfoRow: View {
        let icon: String
        let label: String
        let value: String

        var body: some View {
            HStack(spacing: BloomyTheme.spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(BloomyTheme.palette.accent)
                    .frame(width: 32)

                Text(label)
                    .font(BloomyTheme.typography.body.font)
                    .foregroundStyle(BloomyTheme.palette.mutedText)

                Spacer()

                Text(value)
                    .font(BloomyTheme.typography.bodyBold.font)
                    .foregroundStyle(BloomyTheme.palette.primaryText)
            }
            .padding(.vertical, BloomyTheme.spacing.sm)
            .padding(.horizontal, BloomyTheme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BloomyTheme.radii.medium)
                    .fill(BloomyTheme.palette.elevatedSurface)
            )
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func exactAge(_ profile: BabyProfile) -> String {
        let days = profile.ageInDays
        let weeks = profile.ageInWeeks
        let months = profile.ageInMonths

        if days <= 7 {
            return "\(days)d"
        } else if days <= 90 {
            let remainingDays = days % 7
            return remainingDays > 0 ? "\(weeks)w \(remainingDays)d" : "\(weeks)w"
        } else {
            let remainingDays = days - (months * 30)
            return remainingDays > 0 ? "\(months)m \(remainingDays)d" : "\(months)m"
        }
    }

    private func loadStatistics() async {
        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            let events = try await container.eventsRepository.events(in: nil, kind: nil)
            totalEventsCount = events.count
        } catch {
            totalEventsCount = 0
        }
    }
}

// MARK: - Edit Profile View

private struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let profile: BabyProfile
    let onSave: (String, UIImage?) -> Void

    @State private var name: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false

    init(profile: BabyProfile, onSave: @escaping (String, UIImage?) -> Void) {
        self.profile = profile
        self.onSave = onSave
        self._name = State(initialValue: profile.name)
        self._selectedImage = State(initialValue: profile.photo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(BloomyTheme.palette.accent.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(BloomyTheme.palette.accent)
                                )
                        }
                        Spacer()
                    }
                    .padding(.vertical, BloomyTheme.spacing.md)

                    Button(AppCopy.string(for: "profile.changePhoto")) {
                        showImagePicker = true
                    }
                }

                Section {
                    TextField(AppCopy.string(for: "profile.name"), text: $name)
                } header: {
                    Text(AppCopy.string(for: "profile.name"))
                }
            }
            .navigationTitle(Text(AppCopy.string(for: "profile.edit")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.Common.save) {
                        onSave(name, selectedImage)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Create Profile View

private struct CreateProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (String, Date, UIImage?) -> Void

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(BloomyTheme.palette.accent.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(BloomyTheme.palette.accent)
                                )
                        }
                        Spacer()
                    }
                    .padding(.vertical, BloomyTheme.spacing.md)

                    Button(AppCopy.string(for: "profile.addPhoto")) {
                        showImagePicker = true
                    }
                }

                Section {
                    TextField(AppCopy.string(for: "profile.name.placeholder"), text: $name)
                } header: {
                    Text(AppCopy.string(for: "profile.name"))
                }

                Section {
                    DatePicker(
                        AppCopy.string(for: "profile.birthDate"),
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                } header: {
                    Text(AppCopy.string(for: "profile.birthDate"))
                }
            }
            .navigationTitle(Text(AppCopy.string(for: "profile.create")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.Common.save) {
                        onCreate(name, birthDate, selectedImage)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
                    .ignoresSafeArea()
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
