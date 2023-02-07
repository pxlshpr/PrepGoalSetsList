import SwiftUI
import PrepDataTypes

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
                .fontWeight(.medium)
            Spacer()
            Text("\(viewModel.goalSet.goals.count) goal\(viewModel.goalSet.goals.count > 1 ? "s" : "")")
                .foregroundColor(.secondary)
        }
        
    }
}
