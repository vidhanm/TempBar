import Foundation

@_silgen_name("IOHIDEventSystemClientCreate") func IOHIDEventSystemClientCreate(_ a: CFAllocator?) -> Unmanaged<CFTypeRef>?
@_silgen_name("IOHIDEventSystemClientSetMatching") func IOHIDEventSystemClientSetMatching(_ c: CFTypeRef, _ m: CFDictionary) -> Int32
@_silgen_name("IOHIDEventSystemClientCopyServices") func IOHIDEventSystemClientCopyServices(_ c: CFTypeRef) -> Unmanaged<CFArray>?
@_silgen_name("IOHIDServiceClientCopyProperty") func IOHIDServiceClientCopyProperty(_ s: CFTypeRef, _ k: CFString) -> Unmanaged<CFTypeRef>?
@_silgen_name("IOHIDServiceClientCopyEvent") func IOHIDServiceClientCopyEvent(_ s: CFTypeRef, _ t: Int64, _ o: Int32, _ ts: Int64) -> Unmanaged<CFTypeRef>?
@_silgen_name("IOHIDEventGetFloatValue") func IOHIDEventGetFloatValue(_ e: CFTypeRef, _ f: Int32) -> Double

private let client: CFTypeRef? = {
  guard let c = IOHIDEventSystemClientCreate(kCFAllocatorDefault)?.takeRetainedValue() else { return nil }
  let match: [String: Any] = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5]
  _ = IOHIDEventSystemClientSetMatching(c, match as CFDictionary)
  return c
}()

struct Reading { let name: String; let temp: Double }

func readTemps() -> [Reading] {
  guard let c = client, let arr = IOHIDEventSystemClientCopyServices(c)?.takeRetainedValue() else { return [] }
  var out: [Reading] = []
  for i in 0..<CFArrayGetCount(arr) {
    let s = Unmanaged<CFTypeRef>.fromOpaque(CFArrayGetValueAtIndex(arr, i)!).takeUnretainedValue()
    guard let name = IOHIDServiceClientCopyProperty(s, "Product" as CFString)?.takeRetainedValue() as? String,
          let ev = IOHIDServiceClientCopyEvent(s, 15, 0, 0)?.takeRetainedValue() else { continue }
    let t = IOHIDEventGetFloatValue(ev, 15 << 16)
    if t > 0 && t < 120 { out.append(Reading(name: name, temp: t)) }
  }
  return out
}

struct Summary {
  let socMax: Double, socAvg: Double, battery: Double?, ssd: Double?
  static func current() -> Summary? {
    let all = readTemps()
    let die = all.filter { $0.name.contains("tdie") }.map(\.temp)
    guard !die.isEmpty else { return nil }
    let bat = all.filter { $0.name.contains("battery") }.map(\.temp)
    let ssd = all.filter { $0.name.contains("NAND") }.map(\.temp)
    return Summary(socMax: die.max()!, socAvg: die.reduce(0,+)/Double(die.count),
                   battery: bat.max(), ssd: ssd.max())
  }
}
