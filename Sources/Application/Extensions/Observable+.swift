//
//  Observable+.swift
//  OperantKit
//
//  Created by Yuto Mizutani on 2018/10/22.
//

import RxSwift

public extension Observable {
    /// Add extended entity for entities
    func extend(entity e: ResponseEntity, entities: ResponseEntity...) -> Observable<E> {
        return extend(entity: e, entities: entities)
    }

    /// Add extended entity for entities
    func extend(entity e: ResponseEntity, entities: [ResponseEntity]) -> Observable<E> {
        return self.do(onNext: { _ in
            for entity in entities {
                entity.numOfResponses += e.numOfResponses
                entity.milliseconds += e.milliseconds
            }
        })
    }

    /// Add extended number of responses for entities
    func extend(response numOfResponses: Int, entities: ResponseEntity...) -> Observable<E> {
        return extend(response: numOfResponses, entities: entities)
    }

    /// Add extended number of responses for entities
    func extend(response numOfResponses: Int, entities: [ResponseEntity]) -> Observable<E> {
        return self.do(onNext: { _ in
            for entity in entities {
                entity.numOfResponses += numOfResponses
            }
        })
    }

    /**
        Add `Immutable` extended milliseconds for entities. The time parameter will set when declarations.

        - important:
            You can't variable Milliseconds parameter! In Swift, value types are pass-by-value.

        - seealso:
            [Value and Reference Types - Swift Blog - Apple Developer](https://developer.apple.com/swift/blog/?id=10)
    */
    func extend(time milliseconds: Milliseconds, entities: ResponseEntity...) -> Observable<E> {
        return extend(time: milliseconds, entities: entities)
    }

    /**
         Add `Immutable` extended milliseconds for entities. The time parameter will set when declarations.

         - important:
            You can't variable Milliseconds parameter! In Swift, value types are pass-by-value.

         - seealso:
            [Value and Reference Types - Swift Blog - Apple Developer](https://developer.apple.com/swift/blog/?id=10)
     */
    func extend(time milliseconds: Milliseconds, entities: [ResponseEntity]) -> Observable<E> {
        return self.do(onNext: { _ in
            for entity in entities {
                entity.milliseconds += milliseconds
            }
        })
    }

    /// Add mutable extended milliseconds for entities. The time parameter will get when called.
    func extend(time milliseconds: @escaping () -> Milliseconds, entities: ResponseEntity...) -> Observable<E> {
        return extend(time: milliseconds, entities: entities)
    }

    /// Add mutable extended milliseconds for entities. The time parameter will get when called.
    func extend(time milliseconds: @escaping () -> Milliseconds, entities: [ResponseEntity]) -> Observable<E> {
        return self.do(onNext: { _ in
            for entity in entities {
                entity.milliseconds += milliseconds()
            }
        })
    }

    func updateExtendProperty(_ schedules: [ScheduleUseCase], entity: ResponseEntity) -> Observable<E> {
        return flatMap { observer -> Observable<E> in
            return Observable<Void>.zip(
                schedules.map { $0.repository.updateExtendProperty(entity).asObservable() }
                )
                .map { _ in observer }
        }
    }
    func updateExtendProperty(_ schedules: [ScheduleUseCase], entity: @escaping () -> ResponseEntity) -> Observable<E> {
        return flatMap { observer -> Observable<E> in
            return Observable<Void>.zip(
                schedules.map { $0.repository.updateExtendProperty(entity).asObservable() }
                )
                .map { _ in observer }
        }
    }

    func clearExtendProperty(_ schedules: [ScheduleUseCase]) -> Observable<E> {
        return flatMap { observer -> Observable<E> in
            return Observable<Void>.zip(
                schedules.map { $0.repository.clearExtendProperty().asObservable() }
                )
                .map { _ in observer }
        }
    }

    func updateLastReinforcementProperty(_ schedules: [ScheduleUseCase], entity: ResponseEntity) -> Observable<E> {
        return flatMap { observer -> Observable<E> in
            return Observable<Void>.zip(
                schedules.map { $0.repository.updateLastReinforcementProperty(entity).asObservable() }
                )
                .map { _ in observer }
        }
    }
}
