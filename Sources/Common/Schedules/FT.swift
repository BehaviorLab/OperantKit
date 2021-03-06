//
//  FT.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2018/11/13.
//

import RxSwift

extension ResponseEntity {

    /// Fixed time schedule
    ///
    /// - Tag: .fixedTime()
    func fixedTime(_ value: Milliseconds) -> Bool {
        return milliseconds >= value
    }
}

public extension Single where Element == ResponseEntity {

    /// Fixed time schedule
    ///
    /// - important: In order to distinguish from Time schedule, there is a limitation of one or more responses since last time.
    /// - Parameter value: Reinforcement value
    /// - Complexity: O(1)
    /// - Tag: .FT()
    func FT(_ value: @escaping @autoclosure () -> Milliseconds) -> Single<Bool> {
        return map { r in r.fixedTime(value()) }
    }

    /// Fixed time schedule
    ///
    /// - important: In order to distinguish from Time schedule, there is a limitation of one or more responses since last time.
    /// - Parameter value: Reinforcement value
    /// - Complexity: O(1)
    /// - Tag: .FT()
    func FT(_ value: Single<Int>) -> Single<Bool> {
        return flatMap { r in value.map { v in r.fixedTime(v) } }
    }
}
