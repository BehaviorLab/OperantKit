//
//  ExtinctionScheduleUseCase.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2018/11/02.
//

import RxSwift

public struct ExtinctionScheduleUseCase {
    public init() {}
}

extension ExtinctionScheduleUseCase: ScheduleUseCase {
    public var scheduleType: ScheduleType {
        return .extinction
    }

    public var extendEntity: ResponseEntity {
        return ResponseEntity()
    }

    public func decision(_ observer: Observable<ResponseEntity>) -> Observable<ReinforcementResult> {
        return observer.EXT()
    }
}
