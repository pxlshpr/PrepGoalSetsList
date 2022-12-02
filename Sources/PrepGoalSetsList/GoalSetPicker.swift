import SwiftUI
import PrepDietForm
import PrepDataTypes
import SwiftUISugar
import SwiftHaptics
import PrepCoreDataStack


public struct GoalSetPicker: View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: ViewModel
    
    @State var showingAddGoalSet: Bool = false
    @State var goalSets: [GoalSet] = []

    @State var isDismissing = false
    
    let showCloseButton: Bool

    public init(
        date: Date,
        showCloseButton: Bool = false,
        selectedGoalSet: GoalSet? = nil,
        didSelectGoalSet: @escaping ((GoalSet?, Day?) -> ())
    ) {
        self.init(
            date: date,
            meal: nil,
            showCloseButton: showCloseButton,
            selectedGoalSet: selectedGoalSet,
            didSelectGoalSet: didSelectGoalSet
        )
    }

    public init(
        meal: DayMeal?,
        showCloseButton: Bool = false,
        selectedGoalSet: GoalSet? = nil,
        didSelectGoalSet: @escaping ((GoalSet?, Day?) -> ())
    ) {
        self.init(
            date: nil,
            meal: meal,
            showCloseButton: showCloseButton,
            selectedGoalSet: selectedGoalSet,
            didSelectGoalSet: didSelectGoalSet
        )
    }

    private init(
        date: Date?,
        meal: DayMeal?,
        showCloseButton: Bool = false,
        selectedGoalSet: GoalSet? = nil,
        didSelectGoalSet: @escaping ((GoalSet?, Day?) -> ())
    ) {
        /// We set the `type` based on whether a `date` was provided, as the `meal: DayMeal` could be nil
        /// when using this to pick a `GoalSet` for a meal in the `MealForm`.
        /// (it's currently used when switching meal types in the `MealItemMeters` component).
        let type: GoalSetType = date != nil ? .day : .meal
        _goalSets = State(initialValue: DataManager.shared.goalSets(for: type))
        
        self.showCloseButton = showCloseButton
        
        let viewModel = ViewModel(
            type: type,
            date: date,
            meal: meal,
            selectedGoalSet: selectedGoalSet,
            didSelectGoalSet: didSelectGoalSet
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        content
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { leadingContents }
            .toolbar { trailingContents }
            .onAppear(perform: appeared)
            .fullScreenCover(isPresented: $showingAddGoalSet, content: { addGoalSetSheet })
    }
    
    //MARK: Content
    
    @ViewBuilder
    var content: some View {
        if isEmpty {
            emptyContent
        } else {
            list
        }
    }
    
    var list: some View {
        List {
            Section {
                ForEach(goalSets, id: \.self) { goalSet in
                    button(for: goalSet)
                }
            }
            Section {
                removeButton
            }
        }
    }
    
    @ViewBuilder
    var removeButton: some View {
//        if let selectedGoalSet, let didTapGoalSet, !isDismissing {
        if !isDismissing {
            Button(role: .destructive) {
//                didTapGoalSet(selectedGoalSet)
                viewModel.removeGoalSet()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove \(viewModel.type.description)")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
    }
    
    func button(for goalSet: GoalSet) -> some View {
        var isSelectedGoalSet: Bool {
            viewModel.selectedGoalSet?.id == goalSet.id
        }
        
        return Button {
            isDismissing = true
            dismiss()
            viewModel.selectGoalSet(goalSet)
        } label: {
            HStack {
                Image(systemName: "checkmark")
                    .opacity(isSelectedGoalSet ? 1 : 0)
                label(for: goalSet)
            }
        }
    }
    
    func label(for goalSet: GoalSet) -> some View {
        HStack {
            Text(goalSet.emoji)
            Text(goalSet.name)
                .foregroundColor(.primary)
            Spacer()
        }
    }

    var emptyContent: some View {
        VStack {
            Text("You haven't created any \(viewModel.type.description.lowercased())s")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.tertiaryLabel))
            addEmptyButton
        }
        .padding()
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .foregroundColor(Color(.quaternarySystemFill))
        )
        .padding(.horizontal, 50)
    }
    
    //MARK: Helper Views
    
    var addEmptyButton: some View {
        return Button {
            Haptics.feedback(style: .soft)
            showingAddGoalSet = true
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Add a \(viewModel.type.description)")
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color.accentColor)
            )
        }
        .buttonStyle(.borderless)
    }
    
    var leadingContents: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if showCloseButton {
                Button {
                    Haptics.feedback(style: .soft)
                    dismiss()
                } label: {
                    closeButtonLabel
                }
            }
        }
    }
    var trailingContents: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !isEmpty {
                Button {
                    Haptics.feedback(style: .soft)
                    showingAddGoalSet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    var addGoalSetSheet: some View {
        GoalSetForm(
            type: viewModel.type,
            existingGoalSet: nil,
            bodyProfile: DataManager.shared.user?.bodyProfile
        ) { goalSet, bodyProfile in
            
            /// Save it to the backend
            DataManager.shared.addGoalSetAndBodyProfile(goalSet, bodyProfile: bodyProfile)
            
            /// Add it to the local array
            withAnimation {
                goalSets.append(goalSet)
            }
            
            /// Select the goal in the backend
            viewModel.selectGoalSet(goalSet)
            
            /// Dismiss the form
            dismiss()
        }
    }
    
    //MARK: Convenience
    
    var isEmpty: Bool {
        goalSets.isEmpty
    }
    
    //MARK: Actions
    
    func appeared() {
//        loadDiets()
    }
    
//    func loadDiets() {
//        Task {
//            let goalSets = DataManager.shared.goalSets
//            let diets = goalSets.filter { $0.isDiet }
//            await MainActor.run {
//                withAnimation {
//                    self.diets = diets
//                }
//            }
//        }
//    }
}
