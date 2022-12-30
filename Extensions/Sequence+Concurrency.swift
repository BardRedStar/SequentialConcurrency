//
//  Sequence+Concurrency.swift
//
//  Created by Denis Kovalev
//

import Foundation

extension Sequence {
    /// Runs asynchronous `operation` lambda for each element in the Sequence synchronously.
    /// Awaits previous step completion before performing the next operation
    func syncForEach(_ operation: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await operation(element)
        }
    }

    /// Runs asynchronous `operation` lambda for each element in the Sequence asynchronously.
    /// Performs operations in parallel and returns after all tasks are completed
    func asyncForEach(_ operation: @escaping (Element) async throws -> Void) async rethrows {
        await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
        }
    }

    /// Runs asynchronous `transform` lambda for each element in the Sequence synchronously.
    /// Awaits previous step completion before performing the next transformation
    func syncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    /// Runs asynchronous `transform` lambda for each element in the Sequence asynchronously.
    /// Performs transformations in parallel and returns mapped elements in the same order.
    func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.syncMap { task in
            try await task.value
        }
    }

    /// Runs asynchronous `transform` lambda for each element in the Sequence synchronously.
    /// Awaits previous step completion before performing the next transformation.
    /// Operations that returned `nil` won't be added to the result array
    func syncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let result = try await transform(element) {
                values.append(result)
            }
        }

        return values
    }

    /// Runs asynchronous `transform` lambda for each element in the Sequence asynchronously.
    /// Performs transformations in parallel and returns mapped elements in the same order.
    /// Operations that returned `nil` won't be added to the result array
    func asyncCompactMap<T>(_ transform: @escaping (Element) async throws -> T?) async rethrows -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }

        return try await tasks.syncCompactMap { task in
            try await task.value
        }
    }
}
