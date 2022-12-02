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

    @State var refreshBool: Bool = false
    
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
            .id(refreshBool)
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
        if viewModel.selectedGoalSet != nil, !isDismissing {
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
                label(for: goalSet)
                Spacer()
                durationPicker
                Image(systemName: "checkmark")
                    .opacity(isSelectedGoalSet ? 1 : 0)
            }
        }
    }
    
    var durationPicker: some View {
        HStack {
            Text("1 hour")
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote)
                .foregroundColor(Color(.tertiaryLabel))
            Text("30 min.")
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote)
                .foregroundColor(Color(.tertiaryLabel))
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
//        refreshBool.toggle()
    }
}

struct GoalSetCell: View {

    class ViewModel: ObservableObject {
        @Published var goalSet: GoalSet
        init(goalSet: GoalSet) {
            self.goalSet = goalSet
        }
    }
    
    @StateObject var viewModel: ViewModel
    
    init(goalSet: GoalSet) {
        let viewModel = ViewModel(goalSet: goalSet)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        HStack {
            Text(viewModel.goalSet.emoji)
            Text(viewModel.goalSet.name)
                .foregroundColor(.primary)
            Spacer()
        }
    }

}

struct GoalSetPickerCell: View {
    
    class ViewModel: ObservableObject {
        @Published var goalSet: GoalSet
        init(goalSet: GoalSet) {
            self.goalSet = goalSet
        }
    }

    @StateObject var viewModel: ViewModel
    
    init(goalSet: GoalSet) {
        let viewModel = ViewModel(goalSet: goalSet)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack {
            GoalSetCell(goalSet: viewModel.goalSet)
        }
    }
}

import PrepMocks

struct GoalSetCellPreview: View {
    
    var goalSet: GoalSet {
        GoalSet(
            id: UUID(),
            type: .day,
            name: "Cutting",
            emoji: "🫃🏽",
            goals: [],
            syncStatus: .notSynced,
            updatedAt: 0,
            deletedAt: nil
        )
    }
    
    var body: some View {
        FormStyledScrollView {
            FormStyledSection {
                GoalSetCell(goalSet: goalSet)
            }
        }
    }
}

struct GoalSetPickerCellPreview: View {
    
    var goalSet: GoalSet {
        GoalSet(
            id: UUID(),
            type: .meal,
            name: "Pre-Workout Meal",
            emoji: "🏋🏽‍♂️",
            goals: [
                .init(type: .macro(.quantityPerWorkoutDuration(.min), .carb),
                      lowerBound: 1, upperBound: nil)
            ],
            syncStatus: .notSynced,
            updatedAt: 0,
            deletedAt: nil
        )
    }

    
    var body: some View {
        FormStyledScrollView {
            FormStyledSection {
                GoalSetPickerCell(goalSet: goalSet)
            }
        }
    }
}

struct GoalSetCell_Previews: PreviewProvider {
    static var previews: some View {
        GoalSetCellPreview()
    }
}

struct GoalSetPickerCell_Previews: PreviewProvider {
    static var previews: some View {
        GoalSetPickerCellPreview()
    }
}
