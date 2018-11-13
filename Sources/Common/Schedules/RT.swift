//
//  RT.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2018/11/13.
//

import RxSwift

extension Observable where E == ResponseEntity {

    /// Random time schedule
    public func RT(_ value: Int, with entities: E...) -> Observable<ReinforcementResult> {
        return self
            .randomTime(value, entities)
    }

    /// RT logic
    func randomTime(_ value: Int, _ entities: [E]) -> Observable<ReinforcementResult> {
        return self.fixedTime(value, entities)
    }
}