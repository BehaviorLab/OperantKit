//
//  Brown&Jenkins(1968).swift
//  journals
//
//  Created by Yuto Mizutani on 2018/11/16.
//

import RxSwift
import RxCocoa
import OperantKit


public struct AlternativeScheduleUseCase2: ScheduleUseCase {
    public var repository: ScheduleRespository
    public var subSchedules: [ScheduleUseCase]

    public var scheduleType: ScheduleType {
        return ScheduleType(
            rawValue: UInt64.max,
            shortName: "Alt(\(subSchedules.map { $0.scheduleType.shortName }.joined(separator: ", ")))",
            longName: "Alternative(\(subSchedules.map { $0.scheduleType.longName }.joined(separator: ", ")))"
        )
    }

    public init(_ subSchedules: ScheduleUseCase..., repository: ScheduleRespository = ScheduleRespositoryImpl(), isShared: Bool = true) {
        self.repository = repository
        self.subSchedules = subSchedules
        if isShared {
            self.subSchedules.forEach { $0.repository.recorder = self.repository.recorder }
        }
    }

    public init(_ subSchedules: [ScheduleUseCase], repository: ScheduleRespository = ScheduleRespositoryImpl(), isShared: Bool = true) {
        self.repository = repository
        self.subSchedules = subSchedules
        if isShared {
            self.subSchedules.forEach { $0.repository.recorder = self.repository.recorder }
        }
    }

    public func decision(_ observer: Observable<ResponseEntity>, isUpdateIfReinforcement: Bool) -> Observable<ResultEntity> {
        let sharedObserver = observer.share(replay: 1)
        let observables: [Observable<ResultEntity>] = subSchedules.map { $0.decision(sharedObserver, isUpdateIfReinforcement: false) }

        let result = sharedObserver.flatMap { observer in
            return Observable.zip(observables)
                .map { ResultEntity(!$0.filter({ $0.isReinforcement }).isEmpty, observer) }
        }

        return !isUpdateIfReinforcement ? result : result
            .flatMap { observer -> Observable<ResultEntity> in
                guard observer.isReinforcement else { return Observable.just(observer) }
                return self.updateValue(result)
        }
    }

    public func updateValue(_ observer: Observable<ResultEntity>) -> Observable<ResultEntity> {
        let sharedObserver = observer.share(replay: 1)
        let observables: [Observable<ResultEntity>] = subSchedules.map { $0.updateValue(sharedObserver) }

        return sharedObserver
            .flatMap { observer -> Observable<ResultEntity> in
                return Observable.zip(
                    self.repository.clearExtendProperty().asObservable(),
                    self.repository.updateLastReinforcementProperty(observer.entity).asObservable(),
                    Observable.zip(observables)
                    )
                    .map { _ in observer }
        }
    }
}


/// Brown, P. L., & Jenkins, H. M. (1968). AUTO‐SHAPING OF THE PIGEON'S KEY‐PECK 1. Journal of the experimental analysis of behavior, 11(1), 1-8.
/// - DOI: https://dx.doi.org/10.1901/jeab.1968.11-1
/// - Available link: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1338436/
class BrownAndJenkins1968 {
    func experiment1() {
        let numberOfPairings: Int = 80
        let whiteKeyLightDuration: Seconds = 8
        let trayOperatingDuration: Milliseconds = 4000
        let interTrialInterval: [Seconds] = [Seconds](5...10) // (30...90)
            .filter({ $0 % 5 == 0 })
            .map { TimeUnit.seconds.milliseconds($0) }
            .shuffled()

        var nextInterval: Milliseconds = 0
        var currentOrder: Int = 0
        func updateInterval() {
            nextInterval = interTrialInterval[currentOrder % interTrialInterval.count]
        }

        let timer = WhileLoopTimerUseCase(priority: .high)
        let schedule = AlternativeScheduleUseCase2(FT(whiteKeyLightDuration), CRF())
        let responseAction = PublishSubject<Void>()
        let startTimerAction = PublishSubject<Void>()
        let finishTimerAction = PublishSubject<Void>()
        var isSessionFlag = true
        let duringSR = BehaviorRelay<Bool>(value: false)
        var disposeBag = DisposeBag()

        let respnseObservable = responseAction.response(timer)
            .do(onNext: { print("Response: \($0.numOfResponses), \($0.milliseconds)ms") })
            .share(replay: 1)

        let milliseconds = timer.milliseconds.shared
            .filter({ $0 % 1000 == 0 })
            .share(replay: 1)

        let firstStart = milliseconds.take(1)

        firstStart
            .do(onNext: { _ in print("Session started") })
            .subscribe()
            .disposed(by: disposeBag)

        let timeObservable = milliseconds
            .do(onNext: { print("Time elapsed: \($0)ms") })
            .map { ResponseEntity(numOfResponses: 0, milliseconds: $0) }
            .share(replay: 1)

        let reinforcementOn = schedule.decision(Observable.merge(timeObservable, respnseObservable).share(replay: 1))
            .do(onNext: { print("### \($0.entity.milliseconds), \($0.entity.numOfResponses)") })
            .filter({ _ in !duringSR.value })
            .filter({ $0.isReinforcement })
            .share(replay: 1)

        let reinforcementOff = reinforcementOn
            .do(onNext: { print("SR on: \($0.entity.milliseconds)ms (IRI: \(trayOperatingDuration)ms)") })
            .flatMap { schedule.updateValue(Observable.just($0)) }
            .flatMap { a in schedule.repository.updateExtendProperty(ResponseEntity(numOfResponses: 0, milliseconds: trayOperatingDuration)).map { a } }
            .flatMap { timer.delay(trayOperatingDuration, currentTime: $0.entity.milliseconds) }
            .do(onNext: { print("SR off: \($0)ms") })
            .asObservable()
            .share(replay: 1)

        let nextTrial = Observable<Milliseconds>.merge(
            firstStart,
            reinforcementOff
            )
            .do(onNext: { _ in updateInterval() })
            .do(onNext: { print("ITI on: \($0)ms (Next ITI: \(nextInterval)ms)") })
            .flatMap { a in schedule.repository.updateExtendProperty(ResponseEntity(numOfResponses: 0, milliseconds: nextInterval)).map { a } }
            .flatMap { timer.delay(nextInterval, currentTime: $0) }
            .do(onNext: { print("ITI off: \($0)ms") })
            .asObservable()
            .share(replay: 1)

        nextTrial
            .do(onNext: { _ in print("SD on") })
            .subscribe()
            .disposed(by: disposeBag)

        reinforcementOn
            .do(onNext: { _ in print("SD off") })
            .subscribe()
            .disposed(by: disposeBag)

        reinforcementOff
            .count()
            .do(onNext: { print("Trial \($0)/\(numberOfPairings) finished") })
            .filter({ $0 >= numberOfPairings })
            .mapToVoid()
            .bind(to: finishTimerAction)
            .disposed(by: disposeBag)

        Observable<Bool>.merge(
            reinforcementOn.map { _ in true },
            reinforcementOff.map { _ in false }
            )
            .bind(to: duringSR)
            .disposed(by: disposeBag)

        startTimerAction
            .flatMap { timer.start() }
            .subscribe()
            .disposed(by: disposeBag)

        finishTimerAction
            .flatMap { timer.finish() }
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
