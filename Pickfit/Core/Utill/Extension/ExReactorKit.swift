//
//  ExReactorKit.swift
//  Pickfit
//
//  Created by 김진수 on 9/29/25.
//

import ReactorKit
import RxSwift

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public extension Reactor {
    func run(
        priority: TaskPriority? = nil,
        scheduler: ImmediateSchedulerType = MainScheduler.instance,
        operation: @escaping @MainActor @Sendable (_ send: Send<Mutation>) async -> Void
    ) -> Observable<Mutation> {
        .create { observer in
            let task = Task(priority: priority) {
                let send = Send { observer.onNext($0) }
                await operation(send)
                observer.onCompleted()
            }
            return Disposables.create {
                task.cancel()
            }
        }
        .observe(on: scheduler)
    }
    
    func run(
        priority: TaskPriority? = nil,
        scheduler: ImmediateSchedulerType = MainScheduler.instance,
        operation: @escaping @MainActor @Sendable (_ send: Send<Mutation>) async throws -> Void,
        onError: @escaping (Error) -> Mutation?
    ) -> Observable<Mutation> {
        .create { observer in
            let task = Task(priority: priority) {
                let send = Send { observer.onNext($0) }
                do {
                    try await operation(send)
                } catch {
                    if let m = onError(error) {
                        observer.onNext(m)
                    }
                }
                observer.onCompleted()
            }
            return Disposables.create { task.cancel() }
        }
        .observe(on: scheduler)
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public struct Send<Mutation>: Sendable {
    let send: @Sendable (Mutation) -> Void

    public init(_ send: @escaping @Sendable (Mutation) -> Void) {
        self.send = send
    }

    public func callAsFunction(_ mutation: Mutation) {
        guard !Task.isCancelled else { return }
        self.send(mutation)
    }
}

extension Reactor {
    func handleAuthError(mutation: Observable<Mutation>, logoutMutation: Mutation) -> Observable<Mutation> {
        return mutation.catch { error in
            if case NetworkError.unauthorized = error {
                return .just(logoutMutation)
            }
            throw error
        }
    }
}
