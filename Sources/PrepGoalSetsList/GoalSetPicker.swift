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

    let didTapGoalSet: ((GoalSet) -> ())?
    
    public init(
        type: GoalSetType = .day,
        showCloseButton: Bool = false,
        allowsSelection: Bool = false,
        selectedGoalSet: GoalSet? = nil,
        didTapGoalSet: ((GoalSet) -> ())? = nil
    ) {
        _goalSets = State(initialValue: DataManager.shared.goalSets(for: type))
        
        self.showCloseButton = showCloseButton
        self.didTapGoalSet = didTapGoalSet
        
        let viewModel = ViewModel(
            type: type,
            allowsSelection: allowsSelection,
            selectedGoalSet: selectedGoalSet
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        content
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(viewModel.navigationBarTitleDisplayMode)
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
                    if viewModel.allowsSelection {
                        button(for: goalSet)
                    } else {
                        label(for: goalSet)
                    }
                }
            }
            Section {
                if viewModel.allowsSelection {
                    removeButton
                }
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
