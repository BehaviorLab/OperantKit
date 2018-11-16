//
//  Brown&Jenkins(1968).swift
//  journals
//
//  Created by Yuto Mizutani on 2018/11/16.
//

import RxSwift
import RxCocoa
import OperantKit

/// Brown, P. L., & Jenkins, H. M. (1968). AUTO‐SHAPING OF THE PIGEON'S KEY‐PECK 1. Journal of the experimental analysis of behavior, 11(1), 1-8.
/// - DOI: https://dx.doi.org/10.1901/jeab.1968.11-1
/// - Available link: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1338436/
class BrownAndJenkins1968 {
    func experiment1() {
        typealias Seconds = Int
        typealias Milliseconds = Int
        let numberOfPairings: Int = 80
        let whiteKeyLightDuration: Seconds = 8
        let trayOperatingDuration: Milliseconds = 4000
        let interTrialInterval: [Seconds] = [Seconds](30...90).filter({ $0 % 5 == 0 })

        var nextInterval: Milliseconds = 0
        func updateInterval() {
            nextInterval = TimeUnit.seconds.milliseconds(
                interTrialInterval[Seconds.random(in: 0..<interTrialInterval.count)]
            )
        }

        let timer = IntervalTimerUseCase()
        let schedule: ScheduleUseCase = FT(whiteKeyLightDuration)
        let responseAction = PublishSubject<Void>()
        let startTimerAction = PublishSubject<Void>()
        let finishTimerAction = PublishSubject<Void>()
        var isSessionFlag = true
        var disposeBag = DisposeBag()

        let numOfResponse = responseAction
            .scan(0) { n, _ in n + 1 }
            .asObservable()

        let milliseconds = responseAction
            .asObservable()
            .flatMap { _ in timer.getInterval() }

        Observable.zip(numOfResponse, milliseconds)
            .map { ResponseEntity(numOfResponse: $0.0, milliseconds: $0.1) }
            .do(onNext: { print("Response: \($0.numOfResponse), \($0.milliseconds)ms") })
            .subscribe()
            .disposed(by: disposeBag)

        let timeObservable = timer.milliseconds!
            .filter({ $0 % 1000 == 0 })
            .do(onNext: { print("Time elapsed: \($0)ms") })
            .map { ResponseEntity(numOfResponse: 0, milliseconds: $0) }

        let reinforcementOn = schedule.decision(timeObservable)
            .filter({ $0.isReinforcement })
            .share(replay: 1)

        let reinforcementOff = reinforcementOn
            .do(onNext: { print("SR on: \($0.entity.milliseconds)ms (IRI: \(trayOperatingDuration)ms)") })
            .extend(time: trayOperatingDuration,
                    entities: [schedule.extendEntity])
            .flatMap { timer.delay(trayOperatingDuration, currentTime: $0.entity.milliseconds) }
            .do(onNext: { print("SR off: \($0)ms") })
            .asObservable()
            .share(replay: 1)

        let nextTrial = reinforcementOff
            .do(onNext: { _ in updateInterval() })
            .do(onNext: { print("ITI on: \($0)ms (ITI: \(nextInterval)ms)") })
            .extend(time: nextInterval,
                    entities: [schedule.extendEntity])
            .flatMap { timer.delay(nextInterval, currentTime: $0) }
            .do(onNext: { print("ITI off: \($0)ms") })
            .asObservable()
            .share(replay: 1)

        let firstStart = timer.milliseconds!.take(1)

        Observable<Int>.merge(
            firstStart,
            nextTrial
            )
            .do(onNext: { _ in print("SD on") })
            .subscribe()
            .disposed(by: disposeBag)

        reinforcementOn
            .do(onNext: { _ in print("SD off") })
            .subscribe()
            .disposed(by: disposeBag)

        reinforcementOff
            .scan(0) { n, _ in n + 1 }
            .do(onNext: { print("Trial \($0)/\(numberOfPairings) finished") })
            .filter({ $0 >= numberOfPairings })
            .mapToVoid()
            .subscribe(onNext: {
                finishTimerAction.onNext(())
            })
            .disposed(by: disposeBag)

        firstStart
            .do(onNext: { _ in print("Session started") })
            .subscribe()
            .disposed(by: disposeBag)

        startTimerAction
            .flatMap { timer.start() }
            .subscribe()
            .disposed(by: disposeBag)

        finishTimerAction
            .flatMap { timer.finish() }
            .flatMap { timer.getInterval() }
            .do(onNext: { print("Session finished: \($0)ms") })
            .do(onNext: { _ in print("Program ended if enter any keys") })
            .mapToVoid()
            .subscribe(onNext: {
                isSessionFlag = false
                disposeBag = DisposeBag()
            })
            .disposed(by: disposeBag)

        startTimerAction.onNext(())
        while isSessionFlag {
            let input = readLine()
            guard isSessionFlag else { continue }
            switch input {
            case "q":
                finishTimerAction.onNext(())
            default:
                responseAction.onNext(())
            }
        }
    }
}
