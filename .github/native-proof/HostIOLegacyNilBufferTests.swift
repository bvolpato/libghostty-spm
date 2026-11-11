import Foundation
@testable import GhosttyTerminal
import Testing

extension HostIOHeaderInteropTests {
    @Test
    func legacyNilBufferReturnsBeforeCopy() {
        let writes = HostIOWrites()
        let session = InMemoryTerminalSession(
            write: { writes.record($0) },
            resize: { _ in },
        )
        withExtendedLifetime(session) {
            let context = Unmanaged.passUnretained(session).toOpaque()
            InMemoryTerminalSession.receiveBufferCallback(context, nil, 42)
            #expect(writes.values.isEmpty)
        }
    }
}
