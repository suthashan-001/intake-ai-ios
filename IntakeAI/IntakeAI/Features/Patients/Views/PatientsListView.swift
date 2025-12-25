import SwiftUI

// MARK: - Patients List View
/// Apple Health/Fitness-quality patient list with native iOS interactions
struct PatientsListView: View {
    @StateObject private var viewModel = PatientsViewModel()
    @State private var showAddPatient = false
    @State private var showFilters = false
    @State private var selectedPatient: PatientWithDetails?
    @State private var patientToDelete: PatientWithDetails?
    @State private var showDeleteConfirmation = false
    @State private var refreshTrigger = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.patients.isEmpty {
                    loadingState
                } else if let error = viewModel.error, viewModel.patients.isEmpty {
                    errorState(error)
                } else if viewModel.filteredPatients.isEmpty {
                    emptyState
                } else {
                    patientsList
                }
            }
            .navigationTitle("My Patients")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search patients..."
            )
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.search()
            }
            .sheet(isPresented: $showAddPatient) {
                AddPatientSheet()
            }
            .sheet(isPresented: $showFilters) {
                PatientFiltersSheet(viewModel: viewModel)
            }
            .navigationDestination(item: $selectedPatient) { patient in
                PatientDetailView(patient: patient)
            }
            .confirmationDialog(
                "Delete Patient",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible,
                presenting: patientToDelete
            ) { patient in
                Button("Delete \(patient.patient.firstName)", role: .destructive) {
                    Task {
                        _ = await viewModel.deletePatient(patient)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { patient in
                Text("This will permanently delete \(patient.patient.fullName) and all associated intake data. This action cannot be undone.")
            }
        }
        .task {
            if viewModel.patients.isEmpty {
                await viewModel.loadPatients()
            }
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        ScrollView {
            PatientListSkeleton(count: 6)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Error State
    private func errorState(_ error: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.loadPatients() }
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignSystem.Colors.primary)
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyState: some View {
        if viewModel.searchQuery.isEmpty {
            ContentUnavailableView {
                Label("No Patients Yet", systemImage: "person.3.fill")
            } description: {
                Text("Add your first patient to start managing intake forms.")
            } actions: {
                Button {
                    showAddPatient = true
                } label: {
                    Label("Add Patient", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            }
        } else {
            ContentUnavailableView.search(text: viewModel.searchQuery)
        }
    }

    // MARK: - Patients List
    private var patientsList: some View {
        List {
            // Active filters section
            if viewModel.activeFiltersCount > 0 {
                Section {
                    activeFiltersView
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // Results count
            Section {
                HStack {
                    Text("\(viewModel.totalPatients) patient\(viewModel.totalPatients == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // Patient rows
            Section {
                ForEach(viewModel.filteredPatients) { patient in
                    PatientListRow(patient: patient)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPatient = patient
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                patientToDelete = patient
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                // Send intake link
                            } label: {
                                Label("Send Link", systemImage: "link.badge.plus")
                            }
                            .tint(DesignSystem.Colors.primary)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if patient.patient.phone != nil {
                                Button {
                                    callPatient(patient.patient.phone!)
                                } label: {
                                    Label("Call", systemImage: "phone.fill")
                                }
                                .tint(DesignSystem.Colors.success)
                            }

                            if patient.patient.email != nil {
                                Button {
                                    emailPatient(patient.patient.email!)
                                } label: {
                                    Label("Email", systemImage: "envelope.fill")
                                }
                                .tint(DesignSystem.Colors.info)
                            }
                        }
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentPatient: patient)
                            }
                        }
                }
            }

            // Loading more indicator
            if viewModel.isLoadingMore {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, DesignSystem.Spacing.sm)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            refreshTrigger.toggle()
            await viewModel.refresh()
        }
        .sensoryFeedback(.success, trigger: refreshTrigger)
    }

    // MARK: - Active Filters View
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if let status = viewModel.selectedStatus {
                    FilterChipView(
                        label: status.label,
                        icon: status.icon,
                        color: status.color
                    ) {
                        withAnimation {
                            viewModel.selectedStatus = nil
                        }
                        Task { await viewModel.loadPatients() }
                    }
                }

                if viewModel.showRedFlagsOnly {
                    FilterChipView(
                        label: "Red Flags Only",
                        icon: "exclamationmark.triangle",
                        color: DesignSystem.Colors.error
                    ) {
                        withAnimation {
                            viewModel.showRedFlagsOnly = false
                        }
                    }
                }

                if viewModel.sortBy != .name || viewModel.sortOrder != .ascending {
                    FilterChipView(
                        label: "\(viewModel.sortBy.displayName)",
                        icon: viewModel.sortOrder.icon,
                        color: DesignSystem.Colors.primary
                    ) {
                        withAnimation {
                            viewModel.sortBy = .name
                            viewModel.sortOrder = .ascending
                        }
                    }
                }

                Button("Clear All") {
                    withAnimation {
                        viewModel.clearFilters()
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DesignSystem.Colors.error)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showFilters = true
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }

                Divider()

                Button {
                    showAddPatient = true
                } label: {
                    Label("Add Patient", systemImage: "person.badge.plus")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .symbolRenderingMode(.hierarchical)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAddPatient = true
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Actions
    private func callPatient(_ phone: String) {
        let cleaned = phone.filter { $0.isNumber }
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func emailPatient(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Patient List Row (Apple-style)
struct PatientListRow: View {
    let patient: PatientWithDetails
    @State private var showSymbolAnimation = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Avatar with red flag indicator
            ZStack(alignment: .topTrailing) {
                IAAvatar(name: patient.patient.fullName, size: .large)

                if patient.hasRedFlags {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 20, height: 20)

                        Text("\(patient.redFlagCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: -4)
                }
            }

            // Patient info
            VStack(alignment: .leading, spacing: 2) {
                Text(patient.patient.fullName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text("\(patient.patient.age) years old")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let phone = patient.patient.formattedPhone {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(phone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Status badge
            if let status = patient.displayStatus {
                StatusBadgeView(status: status)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Status Badge View (Native iOS Style)
struct StatusBadgeView: View {
    let status: IntakeStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2.weight(.semibold))

            Text(status.shortLabel)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Filter Chip View
struct FilterChipView: View {
    let label: String
    let icon: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(label)
                .font(.subheadline.weight(.medium))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Filters Sheet (Native iOS Style)
struct PatientFiltersSheet: View {
    @ObservedObject var viewModel: PatientsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Status Section
                Section("Status") {
                    ForEach(IntakeStatus.allCases, id: \.self) { status in
                        Button {
                            withAnimation {
                                if viewModel.selectedStatus == status {
                                    viewModel.selectedStatus = nil
                                } else {
                                    viewModel.selectedStatus = status
                                }
                            }
                        } label: {
                            HStack {
                                Label(status.label, systemImage: status.icon)
                                    .foregroundStyle(status.color)

                                Spacer()

                                if viewModel.selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }

                // Alerts Section
                Section("Alerts") {
                    Toggle(isOn: $viewModel.showRedFlagsOnly) {
                        Label("Red Flags Only", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(DesignSystem.Colors.error)
                    }
                    .tint(DesignSystem.Colors.primary)
                }

                // Sort Section
                Section("Sort By") {
                    ForEach(PatientFilter.SortBy.allCases, id: \.self) { sortOption in
                        Button {
                            withAnimation {
                                if viewModel.sortBy == sortOption {
                                    viewModel.sortOrder = viewModel.sortOrder == .ascending ? .descending : .ascending
                                } else {
                                    viewModel.sortBy = sortOption
                                }
                            }
                        } label: {
                            HStack {
                                Text(sortOption.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if viewModel.sortBy == sortOption {
                                    Image(systemName: viewModel.sortOrder.icon)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset", role: .destructive) {
                        withAnimation {
                            viewModel.clearFilters()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Task {
                            await viewModel.loadPatients()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Add Patient Sheet (Premium)
struct AddPatientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    // Form state
    @State private var currentStep = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sendIntakeLink = true

    // UI state
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var fieldErrors: [String: String] = [:]

    @FocusState private var focusedField: FormField?

    enum FormField: Hashable {
        case firstName, lastName, email, phone
    }

    private let steps = ["Personal", "Contact", "Review"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                stepIndicator

                // Form content
                TabView(selection: $currentStep) {
                    personalInfoStep.tag(0)
                    contactInfoStep.tag(1)
                    reviewStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)

                // Bottom navigation
                bottomNavigation
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("New Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? DesignSystem.Colors.primary : Color(uiColor: .systemGray4))
                            .frame(width: 28, height: 28)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(index == currentStep ? .white : .secondary)
                        }
                    }

                    Text(step)
                        .font(.subheadline.weight(index == currentStep ? .semibold : .regular))
                        .foregroundStyle(index <= currentStep ? .primary : .secondary)
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? DesignSystem.Colors.primary : Color(uiColor: .systemGray4))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Personal Info Step
    private var personalInfoStep: some View {
        Form {
            Section {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .lastName }

                if let error = fieldErrors["firstName"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }

                if let error = fieldErrors["lastName"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                DatePicker(
                    "Date of Birth",
                    selection: $dateOfBirth,
                    in: ...Date(),
                    displayedComponents: .date
                )
            } header: {
                Text("Patient Information")
            } footer: {
                Text("Date of birth is required for identity verification when patients access their intake form.")
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear { focusedField = .firstName }
    }

    // MARK: - Contact Info Step
    private var contactInfoStep: some View {
        Form {
            Section {
                TextField("Email Address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .phone }

                if let error = fieldErrors["email"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                TextField("Phone Number", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .focused($focusedField, equals: .phone)

                if let error = fieldErrors["phone"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Contact Details")
            } footer: {
                Text("At least one contact method is required to send intake links.")
            }

            Section {
                Toggle(isOn: $sendIntakeLink) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Send Intake Link")
                        Text("Immediately send intake form after creation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(DesignSystem.Colors.primary)
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear { focusedField = .email }
    }

    // MARK: - Review Step
    private var reviewStep: some View {
        Form {
            Section("Patient Summary") {
                LabeledContent("Name", value: "\(firstName) \(lastName)")
                LabeledContent("Date of Birth", value: dateOfBirth.formatted(date: .long, time: .omitted))
                LabeledContent("Age", value: "\(Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0) years")
            }

            Section("Contact Information") {
                if !email.isEmpty {
                    LabeledContent("Email", value: email)
                }
                if !phone.isEmpty {
                    LabeledContent("Phone", value: phone)
                }
            }

            Section {
                HStack {
                    Image(systemName: sendIntakeLink ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(sendIntakeLink ? DesignSystem.Colors.primary : .secondary)
                    Text(sendIntakeLink ? "Intake link will be sent" : "No intake link will be sent")
                        .foregroundStyle(sendIntakeLink ? .primary : .secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep < steps.count - 1 {
                Button {
                    if validateCurrentStep() {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            } else {
                Button {
                    savePatient()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                            Text("Create Patient")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
                .disabled(isSaving)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(.ultraThinMaterial)
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignSystem.Colors.success)
                    .symbolEffect(.bounce, value: showSuccess)

                Text("Patient Created!")
                    .font(.title2.bold())

                Text("\(firstName) \(lastName) has been added successfully.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if sendIntakeLink {
                    Label("Intake link sent", systemImage: "paperplane.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Validation
    private func validateCurrentStep() -> Bool {
        fieldErrors = [:]

        switch currentStep {
        case 0:
            if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors["firstName"] = "First name is required"
            }
            if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors["lastName"] = "Last name is required"
            }
        case 1:
            let hasEmail = !email.isEmpty
            let hasPhone = !phone.isEmpty

            if !hasEmail && !hasPhone {
                fieldErrors["email"] = "At least one contact method is required"
            }

            if hasEmail {
                let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
                if email.range(of: emailRegex, options: .regularExpression) == nil {
                    fieldErrors["email"] = "Please enter a valid email address"
                }
            }

            if hasPhone {
                let phoneClean = phone.filter { $0.isNumber }
                if phoneClean.count < 10 {
                    fieldErrors["phone"] = "Please enter a valid phone number"
                }
            }
        default:
            break
        }

        if !fieldErrors.isEmpty {
            DesignSystem.Haptics.notification(.error)
        }

        return fieldErrors.isEmpty
    }

    // MARK: - Save
    private func savePatient() {
        guard validateCurrentStep() else { return }

        isSaving = true
        DesignSystem.Haptics.impact(.medium)

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            DesignSystem.Haptics.notification(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccess = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PatientsListView()
        .environmentObject(AppState())
}
