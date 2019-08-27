//
//  SessionReinforcement.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2019/08/25.
//

import RxSwift

public extension ReinforcementSchedule {
    /// Discrete trial procedure with trial response
    ///
    /// - Complexity: O(1)
    func sessionReinforcement(_ value: Int, numberOfSessions: Int = 1) -> FreeOperant {
        return sessions(by: .reinforcement(value), numberOfSessions: numberOfSessions)
    }
}

public extension ObservableType where Element == Consequence {
    /// Discrete trial procedure with trial response
    ///
    /// - Complexity: O(1)
    func sessionReinforcement(_ value: Int, numberOfSessions: Int = 1) -> Observable<Consequence> {
        return sessions(by: .reinforcement(value), numberOfSessions: numberOfSessions)
    }
}

/// Session reinforcement
///
/// - Complexity: O(1)
public final class SessionReinforcementCondition: FreeOperantCondition {
    private let value: Int

    private var currentValue: Int

    public init(_ value: Int,
                currentValue: Int = 0) {
        self.value = value
        self.currentValue = currentValue
    }

    public func condition(_ consequence: Consequence, lastSessionValue: Response) -> Bool {
        if consequence.isReinforcement {
            currentValue += 1
        }

        let result = currentValue >= value

        // Reset current value
        if result {
            currentValue = 0
        }

        return result
    }
}