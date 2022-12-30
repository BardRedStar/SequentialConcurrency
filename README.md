# Sequential Concurrency

A convenient way to perform sync or async tasks for each element of sequence. 

## 💿 Installation 

Add `Extensions` directory from this repository into your project and that's it!

## 🪄 How to use 

This extension contains async and sync processing methods 
for three types of sequence operations: `forEach`, `map` and `compactMap`.
**Sync** implementations perform each iteration synchronously, one-by-one, and return the value
after all operations will be completed.
**Async** implementations perform each iteration asynchronously, in parallel, and return the value
**in the same order** after all operations will be completed.

For example, we have three concurrent operations:

```swift
func sideEffectOperation(_ number: Int) async throws {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    print(number)
}

func mapperOperation(_ number: Int) async throws -> Int {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    return number * 2
}

func nullableMapperOperation(_ number: Int) async throws -> Int? {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    return number % 2 != 0 ? nil : number / 2
}
```

And we have a sequence (array) of numbers that we must perform operations with:

```swift
let numbers = [1, 2, 3, 4, 5]
```

To perform operations for each object in sequence asynchronously to each other (in parallel), 
we can use `asyncForEach`, `asyncMap` and `asyncCompactMap`.

❗️ Pay attention that `async` implementations take `@escaping` closures, so capture `[weak self]` 
if you perform object-specific operations

```swift
Task {
    do {
        let result = try await numbers
            .asyncForEach { // Prints numbers from 1 to 5 in one second
                try await sideEffectOperation($0)
            }
            .asyncCompactMap { // Returns [2, 4] in one second
                try await nullableMapperOperation($0)
            }
            .asyncMap { // Returns [4, 8] in one second
                try await mapperOperation($0)
            }
        print(result) // Prints [4, 8] after 3 seconds
    }
}
```

To perform operations for each object in sequence synchronously to each other, 
we can use `syncForEach`, `syncMap` and `syncCompactMap`:

```swift
Task {
    do {
        let result = try await numbers
            .syncForEach { // Prints numbers from 1 to 5 in 5 seconds
                try await sideEffectOperation($0)
            }
            .syncCompactMap { // Returns [2, 4] in 5 second
                try await nullableMapperOperation($0)
            }
            .syncMap { // Returns [4, 8] in 2 seconds
                try await mapperOperation($0)
            }
        print(result) // Prints [4, 8] after 12 seconds
    }
}
```

Also, you can mix the asynchronous and synchronous steps up:

```swift
Task {
    do {
        let result = try await numbers
            .asyncForEach { // Prints numbers from 1 to 5 in one second
                try await sideEffectOperation($0)
            }
            .syncCompactMap { // Returns [2, 4] in 5 second
                try await nullableMapperOperation($0)
            }
            .asyncMap { // Returns [4, 8] in one second
                try await mapperOperation($0)
            }
        print(result) // Prints [4, 8] after 7 seconds
    }
}
```
