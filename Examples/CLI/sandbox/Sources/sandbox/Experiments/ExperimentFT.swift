//
//  ExperimentFT.swift
//  sandbox
//
//  Created by Yuto Mizutani on 2018/11/14.
//

import OperantKit
import RxSwift
import RxCocoa

struct ExperimentFT {
    init(_ value: Int, _ unit: TimeUnit) {
        let timer = WhileLoopTimerUseCase(priority: .immediate)
        let schedule: ScheduleUseCase = FT(value, unit: unit)
        let responseAction = PublishSubject<Void>()
        let startTimerAction = PublishSubject<Void>()
        let finishTimerAction = PublishSubject<Void>()
        let disposeBag = DisposeBag()

        _ = responseAction.response(timer)
            .do(onNext: { print("Response: \($0.numOfResponses), \($0.milliseconds)ms") })
            .subscribe()
            .disposed(by: disposeBag)

        let timeObservable = timer.milliseconds.shared
            .map { ResponseEntity(0, $0) }
        
        timeObservable
            .flatMap { schedule.decision($0) }
            .filter({ $0.isReinforcement })
            .subscribe(onNext: {
                print("Reinforcement: \($0.entity.milliseconds)ms")
            })
            .disposed(by: disposeBag)

        startTimerAction
            .flatMap { timer.start() }
            .subscribe(onNext: {
                print("Session started")
            })
            .disposed(by: disposeBag)

        finishTimerAction
            .flatMap { timer.finish() }
            .subscribe(onNext: {
                print("Session finished: \($0)ms")
            })
            .disposed(by: disposeBag)

        startTimerAction.onNext(())
        var bool = true
        while bool {
            switch readLine() {
            case "q":
                bool = false
            default:
                responseAction.onNext(())
            }
        }
        finishTimerAction.onNext(())
    }
}

extension ExperimentFT: Runnable {
    static func run() {
        while true {
            guard
                let value = InputHelper.value(),
                let unit = InputHelper.unit()
                else {
                    continue
            }
            _ = ExperimentFT(value, unit)
            break
        }
    }
}
