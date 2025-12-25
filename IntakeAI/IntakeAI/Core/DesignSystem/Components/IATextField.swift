import SwiftUI

// MARK: - Text Field Component
struct IATextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let autocapitalization: TextInputAutocapitalization
    let errorMessage: String?
    let helperText: String?

    @FocusState private var isFocused: Bool
    @State private var isSecureVisible = false

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        errorMessage: String? = nil,
        helperText: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.errorMessage = errorMessage
        self.helperText = helperText
    }

    private var hasError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }

    private var borderColor: Color {
        if hasError {
            return DesignSystem.Colors.error
        } else if isFocused {
            return DesignSystem.Colors.primary
        } else {
            return DesignSystem.Colors.border
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                        .frame(width: 24)
                        .animation(DesignSystem.Animation.quick, value: isFocused)
                }

                Group {
                    if isSecure && !isSecureVisible {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(DesignSystem.Typography.bodyLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .focused($isFocused)
                .autocorrectionDisabled(isSecure)

                if isSecure {
                    Button(action: {
                        isSecureVisible.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .font(.system(size: DesignSystem.IconSize.md))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }

                if !text.isEmpty && !isSecure {
                    Button(action: {
                        text = ""
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.sm))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(DesignSystem.Colors.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused || hasError ? 2 : 1)
            )
            .animation(DesignSystem.Animation.quick, value: isFocused)
            .animation(DesignSystem.Animation.quick, value: hasError)

            if let error = errorMessage, !error.isEmpty {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSize.xs))
                    Text(error)
                        .font(DesignSystem.Typography.labelSmall)
                }
                .foregroundColor(DesignSystem.Colors.error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let helper = helperText {
                Text(helper)
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(placeholder)
        .accessibilityHint(helperText ?? "")
    }
}

// MARK: - Text Area Component
struct IATextArea: View {
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    let maxCharacters: Int?
    let errorMessage: String?

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat = 100,
        maxCharacters: Int? = nil,
        errorMessage: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
        self.maxCharacters = maxCharacters
        self.errorMessage = errorMessage
    }

    private var hasError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }

    private var borderColor: Color {
        if hasError {
            return DesignSystem.Colors.error
        } else if isFocused {
            return DesignSystem.Colors.primary
        } else {
            return DesignSystem.Colors.border
        }
    }

    private var characterCount: String {
        if let max = maxCharacters {
            return "\(text.count)/\(max)"
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.md)
                }

                TextEditor(text: $text)
                    .font(DesignSystem.Typography.bodyLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .onChange(of: text) { _, newValue in
                        if let max = maxCharacters, newValue.count > max {
                            text = String(newValue.prefix(max))
                        }
                    }
            }
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(DesignSystem.Colors.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused || hasError ? 2 : 1)
            )

            HStack {
                if let error = errorMessage, !error.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.xs))
                        Text(error)
                            .font(DesignSystem.Typography.labelSmall)
                    }
                    .foregroundColor(DesignSystem.Colors.error)
                }

                Spacer()

                if maxCharacters != nil {
                    Text(characterCount)
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Search Field
struct IASearchField: View {
    @Binding var text: String
    let placeholder: String
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)

            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                .fill(DesignSystem.Colors.surfaceSecondary)
        )
        .animation(DesignSystem.Animation.quick, value: isFocused)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            IATextField("Email", text: .constant(""), icon: "envelope")

            IATextField("Password", text: .constant("secret"), icon: "lock", isSecure: true)

            IATextField("With Error", text: .constant("invalid"),
                       errorMessage: "This field is required")

            IATextField("With Helper", text: .constant(""),
                       helperText: "Enter your full name")

            IASearchField(text: .constant(""))

            IASearchField(text: .constant("John Doe"))

            IATextArea("Enter your notes here...", text: .constant(""),
                      maxCharacters: 500)
        }
        .padding()
    }
}
