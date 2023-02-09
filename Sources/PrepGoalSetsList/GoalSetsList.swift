import SwiftUI
import PrepDietForm
import PrepDataTypes
import SwiftUISugar
import SwiftHaptics
import PrepCoreDataStack

public struct GoalSetsList: View {
 
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: ViewModel
    
    @State var showingAddGoalSet: Bool = false
    @State var showingEditGoalSet: Bool = false
    @State var isDismissing = false
    
    let didUpdateGoalSets = NotificationCenter.default.publisher(for: .didUpdateGoalSets)

    public init(
        type: GoalSetType
    ) {
//        _goalSets = State(initialValue: DataManager.shared.goalSets(for: type))
        
        let viewModel = ViewModel(
            type: type,
            goalSets: DataManager.shared.goalSets(for: type)
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        content
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { trailingContents }
            .onAppear(perform: appeared)
            .sheet(isPresented: $showingAddGoalSet, content: { addGoalSetSheet })
            .sheet(isPresented: $showingEditGoalSet, content: { editGoalSetSheet })
            .onReceive(didUpdateGoalSets, perform: didUpdateGoalSets)
    }
    
    func didUpdateGoalSets(notification: Notification) {
        /// Delay this a bit to allow `DataManager` to load them into the array first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            let updatedGoalSets = DataManager.shared.goalSets(for: viewModel.type)
            
            if !updatedGoalSets.hasSameData(as: viewModel.goalSets) {
                withAnimation {
                    viewModel.goalSets = DataManager.shared.goalSets(for: viewModel.type)
                }
            }
            
        }
    }

    //MARK: Content
    
    var content: some View {
        ZStack {
            listLayer
            addButtonLayer
        }
    }
    
    @ViewBuilder
    var listLayer: some View {
        if isEmpty {
            emptyContent
        } else {
            list
        }
    }
    
    var list: some View {
        List {
            ForEach(viewModel.goalSets, id: \.self) { goalSet in
                cell(for: goalSet)
            }
        }
    }
    
    func cell(for goalSet: GoalSet) -> some View {
        var editButton: some View {
            Button {
                viewModel.goalSetToEdit = goalSet
                viewModel.isDuplicating = false
                showingEditGoalSet = true
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
        }
        
        var duplicateButton: some View {
            Button {
                viewModel.goalSetToEdit = goalSet
                viewModel.isDuplicating = true
                showingEditGoalSet = true
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
        }
        
        var deleteButton: some View {
            Button {
                
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
        return Menu {
            editButton
            duplicateButton
            Divider()
            deleteButton
        } label: {
            GoalSetCell(goalSet: goalSet)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.selectionFeedback()
        })
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
    
    var closeButton: some View {
        Button {
            Haptics.feedback(style: .soft)
            dismiss()
        } label: {
            closeButtonLabel
        }
    }
    var trailingContents: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            closeButton
        }
    }
    
    var addButtonLayer: some View {
        
        var saveButton: some View {
            Button {
                Haptics.feedback(style: .soft)
                showingAddGoalSet = true
            } label: {
                Image(systemName:  "plus")
                    .font(.system(size: 25))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        ZStack {
                            Circle()
                                .foregroundStyle(Color.accentColor.gradient)
                        }
                        .shadow(color: Color(.black).opacity(0.2), radius: 3, x: 0, y: 3)
                    )
            }
        }
        
        var layer: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !isEmpty {
                        saveButton
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        
        return layer
    }
    
    var addGoalSetSheet: some View {
        GoalSetForm(
            type: viewModel.type,
            existingGoalSet: nil,
            bodyProfile: DataManager.shared.user?.bodyProfile
        ) { goalSet, bodyProfile, _ in
            
            /// Save it to the backend
            DataManager.shared.addGoalSetAndBodyProfile(goalSet, bodyProfile: bodyProfile)

            /// Add it to the local array
            withAnimation {
                viewModel.goalSets.append(goalSet)
                sortGoalSets()
            }
        }
    }
    
    func sortGoalSets() {
        viewModel.goalSets.sort(by: {
            if $0.name == $1.name { return $0.emoji < $1.emoji }
            return $0.name < $1.name
        })
    }
    
    @ViewBuilder
    var editGoalSetSheet: some View {
        if let goalSetToEdit = viewModel.goalSetToEdit {
            GoalSetForm(
                type: viewModel.type,
                existingGoalSet: goalSetToEdit,
                isDuplicating: viewModel.isDuplicating,
                bodyProfile: DataManager.shared.user?.bodyProfile
            ) { goalSet, bodyProfile, overwritingPastUses in
                
                /// Save it to the backend
                DataManager.shared.addGoalSetAndBodyProfile(goalSet, bodyProfile: bodyProfile)

                /// Add it to the local array
                withAnimation {
                    
                    viewModel.goalSets.append(goalSet)
                    
                    if !viewModel.isDuplicating {
                        viewModel.goalSets.removeAll(where: { $0.id == goalSetToEdit.id })
                    }
                    sortGoalSets()
                }
                
                /// If we're not duplicating it, soft-delete the previous one `deletedAt`
                if !viewModel.isDuplicating {
                    DataManager.shared.deleteGoalSet(goalSetToEdit)
                }
                
                if overwritingPastUses {
                    DataManager.shared.overwritePastUses(
                        of: goalSetToEdit,
                        with: goalSet
                    )
                }


                //TODO: Add a parameter that returns whether user wants to overwrite previous uses or not
                //TODO: Audit and bring this back
                /// [ ] What do we do with the bodyProfile if updated?
//
//                /// Save it to the backend
//                DataManager.shared.addGoalSetAndBodyProfile(goalSet, bodyProfile: bodyProfile)
//
//                /// Add it to the local array
//                withAnimation {
//                    goalSets.append(goalSet)
//                }
            }
        }
    }
    
    //MARK: Convenience
    
    var isEmpty: Bool {
        viewModel.goalSets.isEmpty
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
