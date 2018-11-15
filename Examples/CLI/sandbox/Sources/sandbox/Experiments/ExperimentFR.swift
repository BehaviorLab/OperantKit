//
//  ExperimentFR.swift
//  CLI
//
//  Created by Yuto Mizutani on 2018/11/13.
//

import OperantKit
import RxSwift
import RxCocoa

struct ExperimentFR {
    init(_ value: Int) {
        let timer = IntervalTimerUseCase()
        let schedule: ScheduleUseCase = FR(value)
        let responseAction = PublishSubject<Void>()
        let startTimerAction = PublishSubject<Void>()
        let finishTimerAction = PublishSubject<Void>()
        let disposeBag = DisposeBag()

        let numOfResponse = responseAction
            .scan(0) { n, _ in n + 1 }
            .asObservable()

        let milliseconds = responseAction
            .asObservable()
            .flatMap { _ in timer.getInterval() }

        let response = Observable.zip(numOfResponse, milliseconds)
            .map { ResponseEntity(numOfResponse: $0.0, milliseconds: $0.1) }
            .do(onNext: { print("Response: \($0.numOfResponse), \($0.milliseconds)ms") })
            .share(replay: 1)

        schedule.decision(response)
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
            .flatMap { timer.getInterval() }
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

extension ExperimentFR: Runnable {
    static func run() {
        while true {
            guard
                let value = InputHelper.value()
            else {
                continue
            }
            _ = ExperimentFR(value)
            break
        }
    }
}
