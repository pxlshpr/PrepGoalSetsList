import SwiftUI
import PrepDataTypes

extension GoalSetsList {
    class ViewModel: ObservableObject {
        let type: GoalSetType
        
        init(
            type: GoalSetType
        ) {
            self.type = type
        }
    }
}

extension GoalSetsList.ViewModel {
    
    var navigationTitle: String {
        "\(type.description)s"
    }
}
