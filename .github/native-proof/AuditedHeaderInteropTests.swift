import Foundation
import GhosttyKit
@testable import GhosttyTerminal
import Testing

private func unreadableMimePointer<Element>() -> UnsafePointer<Element> {
    guard let pointer = UnsafePointer<Element>(bitPattern: 1) else {
        preconditionFailure("Cannot construct the unreadable test pointer")
    }
    return pointer
}

struct AuditedHeaderInteropTests {
    @Test
    func completionPayloadPreservesBinaryDataAndMimeLists() {
        let bytes = Data([0, 0xff, 0x61, 0])
        let contents = [
            TerminalClipboardContent(mime: "application/octet-stream", data: bytes),
            TerminalClipboardContent(mime: "text/plain", data: Data()),
        ]
        withClipboardCompletePayload(
            contents: contents,
            available: ["text/plain", "application/octet-stream"],
            confirmed: true,
            remember: false,
        ) { pointer in
            let raw = pointer.pointee
            guard raw.contents_len == 2, let contents = raw.contents,
                  raw.available_len == 2, let available = raw.available
            else {
                Issue.record("The completion payload lost its representations or MIME list")
                return
            }
            let mime: UnsafePointer<CChar>? = contents[0].mime
            let data: UnsafePointer<CChar>? = contents[0].data
            let firstAvailable: UnsafePointer<CChar>? = available[0]
            let secondAvailable: UnsafePointer<CChar>? = available[1]
            guard let mime, let data, let firstAvailable, let secondAvailable else {
                Issue.record("The completion payload contains an absent C string or buffer")
                return
            }
            #expect(String(cString: mime) == "application/octet-stream")
            #expect(Data(bytes: data, count: contents[0].len) == bytes)
            #expect(contents[1].len == 0)
            #expect(String(cString: firstAvailable) == "text/plain")
            #expect(String(cString: secondAvailable) == "application/octet-stream")
            #expect(raw.confirmed && !raw.remember)
        }
    }

    @Test
    func emptyCompletionPayloadKeepsZeroLengths() {
        withClipboardCompletePayload(contents: [], available: [], confirmed: false, remember: true) { pointer in
            #expect(pointer.pointee.contents_len == 0)
            #expect(pointer.pointee.available_len == 0)
            #expect(!pointer.pointee.confirmed && pointer.pointee.remember)
        }
    }

    @Test
    func absentContextReturnsBeforeReadingTheClipboard() {
        let read: ghostty_runtime_read_clipboard_cb = terminalControllerReadClipboardCallback
        withClipboardCompletePayload(contents: [], available: ["text/plain"], confirmed: false, remember: false) { pointer in
            guard let available = pointer.pointee.available else {
                Issue.record("The MIME list is missing")
                return
            }
            var state: UInt8 = 0
            withUnsafeMutablePointer(to: &state) { statePointer in
                let result = read(nil, GHOSTTY_CLIPBOARD_STANDARD, UnsafeMutableRawPointer(statePointer), available, 1, false)
                #expect(result == GHOSTTY_CLIPBOARD_READ_UNSUPPORTED)
            }
        }
    }

    @MainActor
    @Test
    func runtimeAndApplicationInitializeWithEmptyArguments() {
        let controller = TerminalController()
        #expect(controller.config != nil)
        #expect(controller.app != nil)
        #expect(controller.lastConfigurationIssue == nil)
    }

    @Test
    func absentContextDoesNotDereferenceUnreadableMimeStorage() {
        let read: ghostty_runtime_read_clipboard_cb = terminalControllerReadClipboardCallback
        var state: UInt8 = 0
        withUnsafeMutablePointer(to: &state) { statePointer in
            let result = read(
                nil,
                GHOSTTY_CLIPBOARD_STANDARD,
                UnsafeMutableRawPointer(statePointer),
                unreadableMimePointer(),
                42,
                false,
            )
            #expect(result == GHOSTTY_CLIPBOARD_READ_UNSUPPORTED)
        }
    }
}
