import RxSwift
import RxTest
import XCTest
@testable import OperantKit

final class FixedTimeScheduleTests: XCTestCase {
    func testFT() {
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(Bool.self)
        let startTime: TestTime = 0
        let completedTime: TestTime = 10000
        let disposeBag = DisposeBag()

        let schedule: ScheduleUseCase = FT(5)

        let testObservable = scheduler.createHotObservable([
            Recorded.next(100, ResponseEntity(numOfResponses: 0, milliseconds: 5000)),
            Recorded.next(200, ResponseEntity(numOfResponses: 0, milliseconds: 10000)),
            Recorded.next(300, ResponseEntity(numOfResponses: 0, milliseconds: 15000)),
            Recorded.next(400, ResponseEntity(numOfResponses: 0, milliseconds: 15000)),
            Recorded.next(500, ResponseEntity(numOfResponses: 0, milliseconds: 1000000)),
            Recorded.next(600, ResponseEntity(numOfResponses: 0, milliseconds: 1000001)),
            Recorded.completed(completedTime)
            ])

        scheduler.scheduleAt(startTime) {
            testObservable
                .flatMap { schedule.decision($0) }
                .map { $0.isReinforcement }
                .subscribe(observer)
                .disposed(by: disposeBag)
        }
        scheduler.start()

        let expectedEvents = [
            Recorded.next(100, true),
            Recorded.next(200, true),
            Recorded.next(300, true),
            Recorded.next(400, false),
            Recorded.next(500, true),
            Recorded.next(600, false),
            Recorded.completed(completedTime)
        ]
        XCTAssertEqual(observer.events, expectedEvents)

        let expectedSubscriptions = [
            Subscription(startTime, completedTime)
        ]
        XCTAssertEqual(testObservable.subscriptions, expectedSubscriptions)
    }
}
