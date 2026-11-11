import Foundation
import libghostty

func verifyHeaderImports() {
    let callback: ghostty_surface_receive_buffer_cb = { userdata, ptr, len in
        let bufferPointer: UnsafePointer<UInt8>? = ptr
        guard let userdata, let bufferPointer else { return }
        _ = userdata
        _ = Data(bytes: bufferPointer, count: len)
    }
    let resize: ghostty_surface_receive_resize_cb = { userdata, _, _, _, _ in
        guard let userdata else { return }
        _ = userdata
    }
    var config = ghostty_surface_config_s()
    config.userdata = nil
    config.receive_userdata = nil
    config.receive_buffer = nil
    config.receive_resize = nil
    config.receive_buffer = callback
    config.receive_resize = resize
    var byte: UInt8 = 0x42
    withUnsafePointer(to: &byte) { callback(nil, $0, 1) }
}
