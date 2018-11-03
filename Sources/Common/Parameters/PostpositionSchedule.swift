//
//  PostpositionSchedule.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2018/11/01.
//

import Foundation

public struct PostpositionSchedule: OptionSet {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    static let RatioSchedule = PostpositionSchedule(rawValue: 1 << 0)
    static let IntervalSchedule = PostpositionSchedule(rawValue: 1 << 1)
    static let TimeSchedule = PostpositionSchedule(rawValue: 1 << 2)
}
