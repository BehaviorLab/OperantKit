//
//  FixedIntervalScheduleUseCase.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2018/11/03.
//

import RxSwift

public struct FixedIntervalScheduleUseCase: ScheduleUseCase {
    public weak var repository: ScheduleRespository?

    public var scheduleType: ScheduleType {
        return .fixedInterval
    }

    public init(repository: ScheduleRespository) {
        self.repository = repository
    }

    public func decision(_ observer: Observable<ResponseEntity>, isUpdateIfReinforcement: Bool = true) -> Observable<ResultEntity> {
        guard let repository = self.repository else { return Observable<ResultEntity>.error(RxError.noElements) }
        let bool = observer.flatMap { observer -> Observable<(ResponseEntity)> in
            guard let repository = self.repository else { return Observable<ResponseEntity>.error(RxError.noElements) }
            return Observable.combineLatest(
                repository.getExtendProperty().asObservable(),
                repository.getLastReinforcementProperty().asObservable()
            )
            .map { (observer - $0.0 - $0.1) }
        }
        .FI(repository.getValue())

        let result = Observable.zip(bool, observer).map { ResultEntity($0.0, $0.1) }

        return !isUpdateIfReinforcement ? result : result
            .flatMap { observer -> Observable<ResultEntity> in
                guard observer.isReinforcement else { return Observable.just(observer) }
                return self.updateValue(result)
            }
    }
}
