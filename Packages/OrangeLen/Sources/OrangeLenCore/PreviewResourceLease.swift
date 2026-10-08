import Foundation
import Darwin

/// Kernel-held leases coordinate expensive parsers across signed app-group
/// processes. A crash automatically releases its slot; no stale PID registry.
final class PreviewResourceLease {
    private let fd: Int32
    init(lane: String, sharedDirectory: URL? = nil) throws {
        var info = mach_task_basic_info(), count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count) } }
        guard result != KERN_SUCCESS || info.resident_size < 512 * 1024 * 1024 else { throw PreviewError.limit("预览内存水位已达 512 MiB，请关闭其他预览后重载") }
        let directory: URL
        if let sharedDirectory { directory = sharedDirectory }
        else {
            guard let group = Bundle.main.object(forInfoDictionaryKey: "OrangeLenAppGroup") as? String,
                  let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { fd = -1; return }
            directory = container.appendingPathComponent("OrangeLenWorkers", isDirectory: true)
        }
        do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        catch { fd = -1; return } // Quick Look may deny group writes despite returning its URL.
        let slots = lane == "directory" ? 1 : lane == "highlight" ? 2 : 4
        var usable = false
        for index in 0..<slots {
            let descriptor = Darwin.open(directory.appendingPathComponent("\(lane)-\(index).lock").path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
            guard descriptor >= 0 else { continue }
            usable = true
            if flock(descriptor, LOCK_EX | LOCK_NB) == 0 { fd = descriptor; return }
            Darwin.close(descriptor)
        }
        if !usable { fd = -1; return }
        throw PreviewError.limit("其他窗口正在处理预览，请稍后重载")
    }
    deinit { if fd >= 0 { flock(fd, LOCK_UN); Darwin.close(fd) } }
}
