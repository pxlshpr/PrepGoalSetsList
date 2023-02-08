import SwiftUI
import PrepDataTypes

extension GoalSetsList {
    class ViewModel: ObservableObject {
        let type: GoalSetType
        var goalSetToEdit: GoalSet?
        var isDuplicating: Bool

        init(type: GoalSetType) {
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
