import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension GoalSetPicker {
    class ViewModel: ObservableObject {
        let type: GoalSetType
        let date: Date?
        let meal: DayMeal?
        let selectedGoalSet: GoalSet?
        
        let didSelectGoalSet: ((GoalSet?, Day?) -> ())

        var day: Day?
        
        init(
            type: GoalSetType,
            date: Date?,
            meal: DayMeal?,
            selectedGoalSet: GoalSet?,
            didSelectGoalSet: @escaping ((GoalSet?, Day?) -> ())
        ) {
            self.type = type
//            self.type = meal != nil ? .meal : .day
            self.date = date
            self.meal = meal
            self.selectedGoalSet = selectedGoalSet
            self.didSelectGoalSet = didSelectGoalSet
        }
    }
}

extension GoalSetPicker.ViewModel {
    
    func selectGoalSet(_ goalSet: GoalSet) {
        do {
            switch type {
            case .day:
                guard let date else { return }
                if selectedGoalSet?.id == goalSet.id {
                    try DataManager.shared.removeGoalSet(on: date)
                    didSelectGoalSet(nil, nil)
                } else {
                    let day = try DataManager.shared.setGoalSet(goalSet, on: date)
                    didSelectGoalSet(goalSet, day)
                }
            case .meal:
                /// [ ] If its for a meal and we have a `Meal` provided, persist the change with the backend
                break
            }
            
 
        } catch {
            print("Error setting GoalSet: \(error)")
        }
    }
    
    func removeGoalSet() {
        guard let selectedGoalSet else { return }
        selectGoalSet(selectedGoalSet)
    }
    
    var navigationTitle: String {
        return "Choose a \(type.description)"
    }    
}
