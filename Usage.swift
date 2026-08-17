import Foundation

/// CPU % and memory usage via Mach host statistics (no subprocesses, negligible cost).
enum Usage {
  private static var lastTicks: (busy: UInt64, total: UInt64)?

  /// CPU utilisation (0–100) since the previous call; nil on first call.
  static func cpu() -> Double? {
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
    var info = host_cpu_load_info_data_t()
    let kr = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
      }
    }
    guard kr == KERN_SUCCESS else { return nil }
    let u = UInt64(info.cpu_ticks.0), s = UInt64(info.cpu_ticks.1), i = UInt64(info.cpu_ticks.2), n = UInt64(info.cpu_ticks.3)
    let busy = u + s + n, total = busy + i
    defer { lastTicks = (busy, total) }
    guard let l = lastTicks, total > l.total else { return nil }
    return Double(busy - l.busy) / Double(total - l.total) * 100
  }

  /// (used GB, total GB) — "used" matches Activity Monitor's Memory Used (active + wired + compressed).
  static func memory() -> (used: Double, total: Double)? {
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    var vm = vm_statistics64_data_t()
    let kr = withUnsafeMutablePointer(to: &vm) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }
    guard kr == KERN_SUCCESS else { return nil }
    let page = Double(vm_kernel_page_size)
    let used = (Double(vm.active_count) + Double(vm.wire_count) + Double(vm.compressor_page_count)) * page
    let total = Double(ProcessInfo.processInfo.physicalMemory)
    return (used / 1e9, total / 1e9)
  }
}
