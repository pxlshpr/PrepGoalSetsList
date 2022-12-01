import SwiftUI
import PrepDataTypes

extension GoalSetPicker {
    class ViewModel: ObservableObject {
        let type: GoalSetType
        let allowsSelection: Bool
//        let currentDate: Date
        let selectedGoalSet: GoalSet?
        
        init(
            type: GoalSetType,
            allowsSelection: Bool,
            selectedGoalSet: GoalSet?
        ) {
            self.selectedGoalSet = selectedGoalSet
            self.type = type
            self.allowsSelection = allowsSelection
        }
    }
}

extension GoalSetPicker.ViewModel {
    
    func selectedGoalSet(_ goalSet: GoalSet) {
        do {
            //TODO: Do these
            /// [ ] If its for a meal, we need to have a meal provided and remove or set it on that meal—persisting the change in the backend
            ///
            /// [ ] If its for a day, we need to take the date we were provided and get DataManager to either
            /// [ ] Remove the goal set on the Day, not creating one if it doesnt exist—but we shouldn't encounter this case, so silently log the error
            /// [ ] Set the goal set on the Day, creating a new one if needed
            /// [ ] Making sure we get back a Day in this case
            /// [ ] Calling the callback with the Day and the set goalset (or nil)
            ///
            /// [ ] If its for a meal, we need to remove or set the goal set on the meal, and call the callback
            ///
            /// [ ] So we need to make sure that when we add a new goal—if we have `allowsSelection`, we should immediately select that goal set and dismiss (pretend like it was selected)
//            if day?.goalSet?.id == tappedGoalSet.id {
//                try DataManager.shared.removeGoalSet(on: date)
//                self.day?.goalSet = nil
//            } else {
//                try DataManager.shared.setGoalSet(tappedGoalSet, on: date)
//                self.day?.goalSet = tappedGoalSet
//            }
            NotificationCenter.default.post(name: .didUpdateDiet, object: nil)
        } catch {
            print("Error setting GoalSet: \(error)")
        }
    }
    
    func removeGoalSet() {
        
    }
    
    var navigationTitle: String {
        return allowsSelection ? "Choose a \(type.description)" : "\(type.description)s"
    }
    
    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        allowsSelection ? .inline : .large
    }
}
