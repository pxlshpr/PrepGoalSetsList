import SwiftUI
import PrepDataTypes

extension GoalSetsList {
    class ViewModel: ObservableObject {
        let type: GoalSetType
        var goalSetToEdit: GoalSet?
        
        init(type: GoalSetType) {
            self.type = type
            goalSetToEdit = nil
        }
    }
}

extension GoalSetsList.ViewModel {
    
    var navigationTitle: String {
        "My \(type.description)s"
    }
}
