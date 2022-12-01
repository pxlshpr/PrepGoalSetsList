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

        init(
            date: Date?,
            meal: DayMeal?,
            selectedGoalSet: GoalSet?,
            didSelectGoalSet: @escaping ((GoalSet?, Day?) -> ())
        ) {
            self.selectedGoalSet = selectedGoalSet
            self.type = meal != nil ? .meal : .day
            self.date = date
            self.meal = meal
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
//                if day?.goalSet?.id == goalSet.id {
//                    try DataManager.shared.removeGoalSet(on: date)
//                    self.day?.goalSet = nil
//                    didSelectGoalSet(nil, nil)
//                } else {
//                    let day = try DataManager.shared.setGoalSet(goalSet, on: date)
//                    self.day = day
//                    didSelectGoalSet(goalSet, day)
//                }
            case .meal:
                /// [ ] If its for a meal, we need to remove or set the goal set on the meal, and call the callback
                break
            }
            
            NotificationCenter.default.post(name: .didUpdateDiet, object: nil)
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
