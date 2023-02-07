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
            ForEach(goalSets, id: \.self) { goalSet in
                Section {
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
                    Image(systemName: "minus.circle")
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
            GoalSetPickerCell(goalSet: goalSet, isSelected: isSelectedGoalSet)
//            HStack {
//                label(for: goalSet)
//                Spacer()
//                durationPicker
//                Image(systemName: "checkmark")
//                    .opacity(isSelectedGoalSet ? 1 : 0)
//            }
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
    
    var isEmpty: Bool {
        goalSets.isEmpty
    }
    
    func appeared() {
//        refreshBool.toggle()
    }
}

//MARK: - GoalSetPickerCell

struct GoalSetPickerCell: View {
    
    class ViewModel: ObservableObject {
        
        @Published var goalSet: GoalSet
        @Published var isSelected: Bool
        
        init(goalSet: GoalSet, isSelected: Bool = false) {
            self.goalSet = goalSet
            self.isSelected = isSelected
        }
        
        var shouldShowDurationPicker: Bool {
            goalSet.containsWorkoutDurationDependentGoal
        }
    }

    @StateObject var viewModel: ViewModel
    
    init(goalSet: GoalSet, isSelected: Bool = false) {
        let viewModel = ViewModel(goalSet: goalSet, isSelected: isSelected)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                GoalSetCell(goalSet: viewModel.goalSet)
                Spacer()
                selectionCheckmark
            }
            if viewModel.shouldShowDurationPicker {
                HStack {
                    Spacer()
                    durationPicker
                }
            }
        }
    }
    
    var durationPicker: some View {
        HStack {
            HStack {
                Text("1 hour")
                    .foregroundColor(Color(.secondaryLabel))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .imageScale(.small)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .font(.footnote)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(Color(.secondarySystemFill))
            )
            HStack {
                Text("30 min.")
                    .foregroundColor(Color(.secondaryLabel))
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .font(.footnote)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(Color(.secondarySystemFill))
            )
        }
    }
    
    var selectionCheckmark: some View {
        
        var selected: some View {
            ZStack {
                Image(systemName: "circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Image(systemName: "checkmark")
                    .imageScale(.small)
                    .foregroundColor(.white)
            }
        }
        
        var notSelected: some View {
            ZStack {
                Image(systemName: "circle.dotted")
                    .imageScale(.large)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }

        return Group {
            if viewModel.isSelected {
                selected
            } else {
                notSelected
            }
        }
        
    }
}

//MARK: - 👁‍🗨 Previews

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
    
    var preworkoutMealType: GoalSet {
        GoalSet(
            id: UUID(),
            type: .meal,
            name: "Pre-Workout Meal",
            emoji: "🍞",
            goals: [
                .init(type: .macro(.quantityPerBodyMass(.weight, .kg), .carb),
                      lowerBound: 1, upperBound: nil),
                .init(type: .energy(.fixed(.kcal)),
                      lowerBound: nil, upperBound: 500),
                .init(type: .macro(.fixed, .protein),
                      lowerBound: 20, upperBound: 25)
            ],
            syncStatus: .notSynced,
            updatedAt: 0,
            deletedAt: nil
        )
    }

    
    var intraWorkoutMealType: GoalSet {
        GoalSet(
            id: UUID(),
            type: .meal,
            name: "Intra-Workout Snack",
            emoji: "🏋🏽‍♂️",
            goals: [
                .init(type: .macro(.quantityPerWorkoutDuration(.min), .carb),
                      lowerBound: 0.5, upperBound: nil)
            ],
            syncStatus: .notSynced,
            updatedAt: 0,
            deletedAt: nil
        )
    }
    
    var postWorkoutMealType: GoalSet {
        GoalSet(
            id: UUID(),
            type: .meal,
            name: "Post-Workout Meal",
            emoji: "🏁",
            goals: [
                .init(type: .macro(.fixed, .carb),
                      lowerBound: nil, upperBound: 50),
                .init(type: .energy(.fixed(.kcal)),
                      lowerBound: nil, upperBound: 500),
                .init(type: .macro(.fixed, .protein),
                      lowerBound: 30, upperBound: 50)
            ],
            syncStatus: .notSynced,
            updatedAt: 0,
            deletedAt: nil
        )
    }
    
    var body: some View {
        FormStyledScrollView {
            FormStyledSection {
                GoalSetPickerCell(goalSet: preworkoutMealType, isSelected: true)
            }
            FormStyledSection {
                GoalSetPickerCell(goalSet: intraWorkoutMealType)
            }
            FormStyledSection {
                GoalSetPickerCell(goalSet: postWorkoutMealType)
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
