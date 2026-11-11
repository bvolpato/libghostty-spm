import Foundation
@testable import GhosttyTerminal
import Testing

final class HostIOWrites: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Data] = []

    func record(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(data)
    }

    var values: [Data] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

struct HostIOHeaderInteropTests {
    @Test
    func nullableContextIsIgnoredAndValidBufferIsCopied() {
        let writes = HostIOWrites()
        let session = InMemoryTerminalSession(
            write: { writes.record($0) },
            resize: { _ in },
        )
        withExtendedLifetime(session) {
            let context = Unmanaged.passUnretained(session).toOpaque()
            var byte: UInt8 = 0x42
            withUnsafePointer(to: &byte) { pointer in
                InMemoryTerminalSession.receiveBufferCallback(nil, pointer, 1)
                #expect(writes.values.isEmpty)
                InMemoryTerminalSession.receiveBufferCallback(context, pointer, 1)
            }
            #expect(writes.values == [Data([0x42])])
        }
    }
}
