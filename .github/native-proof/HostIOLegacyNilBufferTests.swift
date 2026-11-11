import Foundation
import GhosttyKit
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

extension AuditedHeaderInteropTests {
    @MainActor
    @Test
    func legacyNilSearchNeedleStillStartsWithoutAPattern() {
        let delegate = LegacySearchNeedleProbe()
        let bridge = TerminalCallbackBridge(delegate: delegate)
        var action = ghostty_action_s()
        action.tag = GHOSTTY_ACTION_START_SEARCH
        action.action.start_search.needle = nil
        bridge.handleAction(action)
        #expect(delegate.needles == [nil])
    }
}

@MainActor
private final class LegacySearchNeedleProbe: TerminalSurfaceSearchDelegate {
    var needles: [String?] = []

    func terminalDidStartSearch(needle: String?) {
        needles.append(needle)
    }

    func terminalDidEndSearch() {}
    func terminalDidUpdateSearchTotal(_: Int?) {}
    func terminalDidUpdateSearchSelected(_: Int?) {}
}
