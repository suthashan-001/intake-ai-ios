import SwiftUI

// MARK: - Modal Component
struct IAModal<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let subtitle: String?
    let content: Content

    init(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(DesignSystem.Animation.standard) {
                        isPresented = false
                    }
                }

            // Modal content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: DesignSystem.Spacing.xxs) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                            Text(title)
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)

                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }

                        Spacer()

                        IAIconButton(icon: "xmark", style: .secondary, size: .small) {
                            withAnimation(DesignSystem.Animation.standard) {
                                isPresented = false
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.surface)

                Divider()

                // Content
                content
                    .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous))
            .shadow(
                color: DesignSystem.Shadows.elevated.color,
                radius: DesignSystem.Shadows.elevated.radius,
                x: DesignSystem.Shadows.elevated.x,
                y: DesignSystem.Shadows.elevated.y
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .animation(DesignSystem.Animation.spring, value: isPresented)
    }
}

// MARK: - Confirmation Dialog
struct IAConfirmationDialog: View {
    @Binding var isPresented: Bool
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let confirmTitle: String
    let confirmStyle: IAButtonStyle
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?

    init(
        isPresented: Binding<Bool>,
        icon: String = "exclamationmark.triangle.fill",
        iconColor: Color = DesignSystem.Colors.warning,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmStyle: IAButtonStyle = .primary,
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmStyle = confirmStyle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: DesignSystem.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Text
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }

                // Buttons
                VStack(spacing: DesignSystem.Spacing.sm) {
                    IAButton(confirmTitle, style: confirmStyle, isFullWidth: true) {
                        onConfirm()
                        dismiss()
                    }

                    IAButton(cancelTitle, style: .secondary, isFullWidth: true) {
                        onCancel?()
                        dismiss()
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous))
            .shadow(
                color: DesignSystem.Shadows.elevated.color,
                radius: DesignSystem.Shadows.elevated.radius,
                x: DesignSystem.Shadows.elevated.x,
                y: DesignSystem.Shadows.elevated.y
            )
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .animation(DesignSystem.Animation.spring, value: isPresented)
    }

    private func dismiss() {
        withAnimation(DesignSystem.Animation.standard) {
            isPresented = false
        }
    }
}

// MARK: - Bottom Sheet
struct IABottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String?
    let content: Content
    let detents: [PresentationDetent]

    @State private var offset: CGFloat = 0
    @GestureState private var isDragging = false

    init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        detents: [PresentationDetent] = [.medium, .large],
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.detents = detents
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)

                VStack(spacing: 0) {
                    // Drag indicator
                    Capsule()
                        .fill(DesignSystem.Colors.border)
                        .frame(width: 36, height: 5)
                        .padding(.top, DesignSystem.Spacing.sm)
                        .padding(.bottom, DesignSystem.Spacing.xs)

                    // Title
                    if let title = title {
                        HStack {
                            Text(title)
                                .font(DesignSystem.Typography.headlineSmall)
                                .foregroundColor(DesignSystem.Colors.textPrimary)

                            Spacer()

                            IAIconButton(icon: "xmark", style: .secondary, size: .small) {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.sm)

                        Divider()
                    }

                    // Content
                    content
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                }
                .frame(maxWidth: .infinity)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxl, style: .continuous))
                .offset(y: offset)
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            if value.translation.height > 0 {
                                offset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 150 {
                                dismiss()
                            } else {
                                withAnimation(DesignSystem.Animation.spring) {
                                    offset = 0
                                }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(DesignSystem.Animation.spring, value: isPresented)
    }

    private func dismiss() {
        withAnimation(DesignSystem.Animation.standard) {
            isPresented = false
            offset = 0
        }
    }
}

// MARK: - Toast Notification
struct IAToast: View {
    let message: String
    let type: ToastType
    let action: (() -> Void)?

    enum ToastType {
        case success
        case error
        case warning
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return DesignSystem.Colors.success
            case .error: return DesignSystem.Colors.error
            case .warning: return DesignSystem.Colors.warning
            case .info: return DesignSystem.Colors.info
            }
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: DesignSystem.IconSize.md, weight: .semibold))
                .foregroundColor(type.color)

            Text(message)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Spacer()

            if let action = action {
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.system(size: DesignSystem.IconSize.sm, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
        .shadow(
            color: DesignSystem.Shadows.large.color,
            radius: DesignSystem.Shadows.large.radius,
            x: DesignSystem.Shadows.large.x,
            y: DesignSystem.Shadows.large.y
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var showModal = false
        @State private var showConfirmation = false
        @State private var showBottomSheet = false

        var body: some View {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.lg) {
                    IAButton("Show Modal", style: .primary) {
                        showModal = true
                    }

                    IAButton("Show Confirmation", style: .secondary) {
                        showConfirmation = true
                    }

                    IAButton("Show Bottom Sheet", style: .outline) {
                        showBottomSheet = true
                    }

                    Spacer()

                    IAToast(message: "Patient saved successfully", type: .success) {}
                    IAToast(message: "Unable to connect", type: .error) {}
                    IAToast(message: "Session expiring soon", type: .warning) {}
                    IAToast(message: "New update available", type: .info) {}
                }
                .padding()

                if showModal {
                    IAModal(isPresented: $showModal, title: "Add Patient", subtitle: "Enter patient details") {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            IATextField("First Name", text: .constant(""))
                            IATextField("Last Name", text: .constant(""))
                            IAButton("Save", style: .primary, isFullWidth: true) {}
                        }
                    }
                }

                if showConfirmation {
                    IAConfirmationDialog(
                        isPresented: $showConfirmation,
                        icon: "trash.fill",
                        iconColor: DesignSystem.Colors.error,
                        title: "Delete Patient?",
                        message: "This action cannot be undone. All associated intakes and summaries will be permanently deleted.",
                        confirmTitle: "Delete",
                        confirmStyle: .destructive
                    ) {}
                }

                IABottomSheet(isPresented: $showBottomSheet, title: "Filter Patients") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        IATextField("Search", text: .constant(""), icon: "magnifyingglass")
                        IAButton("Apply Filters", style: .primary, isFullWidth: true) {
                            showBottomSheet = false
                        }
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
