import SwiftUI
import PrepDietForm
import PrepDataTypes
import SwiftUISugar
import SwiftHaptics
import PrepCoreDataStack

public struct GoalSetsList: View {
    
    @Environment(\.dismiss) var dismiss
    @State var showingAddGoalSet: Bool = false
    @State var goalSets: [GoalSet] = []

    @State var isDismissing = false
    
    let showCloseButton: Bool
    let allowsSelection: Bool
    let forMealItemForm: Bool

    let selectedGoalSet: GoalSet?
    let didTapGoalSet: ((GoalSet) -> ())?
    let forMeals: Bool
    
    public init(
        forMeals: Bool = false,
        showCloseButton: Bool = false,
        allowsSelection: Bool = false,
        forMealItemForm: Bool = false,
        selectedGoalSet: GoalSet? = nil,
        didTapGoalSet: ((GoalSet) -> ())? = nil
    ) {
        self.forMeals = forMeals
        
        let allGoalSets = DataManager.shared.goalSets
        let goalSets = allGoalSets.filter { forMeals ? $0.isForMeal : $0.isDiet }
        _goalSets = State(initialValue: goalSets)
        
        self.selectedGoalSet = selectedGoalSet
        self.showCloseButton = showCloseButton
        self.allowsSelection = allowsSelection
        self.didTapGoalSet = didTapGoalSet
        self.forMealItemForm = forMealItemForm
    }
    
    var type: String {
        forMeals ? "Meal Type" : "Diet"
    }
    
    public var body: some View {
        content
            .navigationTitle(allowsSelection ? "Choose a \(type)" : "\(type)s")
            .navigationBarTitleDisplayMode(allowsSelection ? .inline : .large)
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
                    if allowsSelection {
                        button(for: goalSet)
                    } else {
                        label(for: goalSet)
                    }
                }
            }
            Section(footer: footer) {
                if allowsSelection {
                    removeButton
                }
            }
        }
    }
    
    @ViewBuilder
    var removeButton: some View {
        if let selectedGoalSet, let didTapGoalSet, !isDismissing {
            Button(role: .destructive) {
                didTapGoalSet(selectedGoalSet)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove \(type)")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if forMealItemForm {
            Text("Your chosen \(type.description) will be saved once you've saved this food.")
        }
    }
    
    func button(for goalSet: GoalSet) -> some View {
        var isSelectedGoalSet: Bool {
            selectedGoalSet?.id == goalSet.id
        }
        
        return Button {
            isDismissing = true
            dismiss()
            didTapGoalSet?(goalSet)
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
            Text("You haven't created any \(type.lowercased())s")
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
                Text("Add a \(type)")
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
            if !isEmpty, !forMealItemForm {
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
            isForMeal: forMeals,
            existingGoalSet: nil,
            bodyProfile: DataManager.shared.user?.bodyProfile
        ) { goalSet, bodyProfile in
            
            do {
                if let bodyProfile {
                    try DataManager.shared.setBodyProfile(bodyProfile)
                }
                try DataManager.shared.addNewGoalSet(goalSet)
            } catch {
                print("Error persisting data")
            }

            /// Add it to the local array
            withAnimation {
                goalSets.append(goalSet)
            }
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

public extension GoalSet {
    var isDiet: Bool {
        !isForMeal
    }
}
