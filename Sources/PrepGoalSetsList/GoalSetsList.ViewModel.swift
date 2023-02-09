import SwiftUI
import PrepDataTypes

extension GoalSetsList {
    class ViewModel: ObservableObject {
        let type: GoalSetType
        var goalSetToEdit: GoalSet?
        var isDuplicating: Bool

        @Published var goalSets: [GoalSet] = []

        init(type: GoalSetType, goalSets: [GoalSet] = []) {
            self.goalSets = goalSets
            self.type = type
            goalSetToEdit = nil
            isDuplicating = false
        }
    }
}

extension GoalSetsList.ViewModel {
    
    var navigationTitle: String {
        "My \(type.description)s"
    }
}
