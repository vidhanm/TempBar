import AppKit

final class Panel: NSView {
  var history: [Double] = []
  var summary: Summary?
  let cap = 100
  override func draw(_ r: NSRect) {
    let W = bounds.width
    let mono = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    let small = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
    let dim = NSColor.secondaryLabelColor, txt = NSColor.labelColor
    func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ f: NSFont, _ c: NSColor, right: Bool = false) {
      let a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: c]
      let sz = (s as NSString).size(withAttributes: a)
      (s as NSString).draw(at: CGPoint(x: right ? x - sz.width : x, y: y), withAttributes: a)
    }
    guard let s = summary, history.count > 1 else { text("Reading sensors…", 14, bounds.height - 22, mono, dim); return }

    // ---- header row: big number + stats ----
    let top = bounds.height
    let big = NSFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
    let col: NSColor = s.socMax >= 90 ? .systemRed : s.socMax >= 75 ? .systemOrange : .controlAccentColor
    text(String(format: "%.1f°", s.socMax), 14, top - 32, big, col)
    text("SoC", 14, top - 45, small, dim)
    let stats = [("avg", s.socAvg), ("low", history.min()!), ("high", history.max()!)]
    var x = W - 14
    for (k, v) in stats.reversed() {
      let vs = String(format: "%.1f°", v)
      text(vs, x, top - 30, mono, txt, right: true)
      text(k, x, top - 43, small, dim, right: true)
      x -= 52
    }
    // ---- chart ----
    let L: CGFloat = 14, R: CGFloat = 36, B: CGFloat = 44, T: CGFloat = 54
    let cw = W - L - R, ch = bounds.height - T - B
    let lo = floor((history.min()! - 1) / 2) * 2, hi = ceil((history.max()! + 1) / 2) * 2
    let span = max(hi - lo, 4)
    func px(_ i: Int) -> CGFloat { L + cw * CGFloat(i) / CGFloat(cap - 1) }
    func py(_ v: Double) -> CGFloat { B + ch * CGFloat((v - lo) / span) }
    // grid + y labels
    NSColor.separatorColor.setStroke()
    for k in 0...2 {
      let v = lo + span * Double(k) / 2, y = py(v)
      let g = NSBezierPath(); g.move(to: CGPoint(x: L, y: y)); g.line(to: CGPoint(x: L + cw, y: y))
      g.lineWidth = 0.5; g.setLineDash([2, 3], count: 2, phase: 0); g.stroke()
      text(String(format: "%.0f°", v), L + cw + 6, y - 6, small, dim)
    }
    // x labels
    for (i, lab) in [(0, "-5m"), (40, "-3m"), (80, "-1m"), (99, "now")] {
      text(lab, px(i) - (i == 99 ? 18 : i == 0 ? 0 : 9), B - 14, small, dim)
    }
    // line + gradient fill
    let off = cap - history.count
    let path = NSBezierPath()
    for (i, v) in history.enumerated() { let p = CGPoint(x: px(i + off), y: py(v)); i == 0 ? path.move(to: p) : path.line(to: p) }
    let fill = path.copy() as! NSBezierPath
    fill.line(to: CGPoint(x: px(cap-1), y: B)); fill.line(to: CGPoint(x: px(off), y: B)); fill.close()
    NSGraphicsContext.saveGraphicsState(); fill.addClip()
    NSGradient(starting: col.withAlphaComponent(0.35), ending: col.withAlphaComponent(0))!.draw(in: NSRect(x: L, y: B, width: cw, height: ch), angle: 90)
    NSGraphicsContext.restoreGraphicsState()
    col.setStroke(); path.lineWidth = 1.5; path.lineJoinStyle = .round; path.stroke()
    // current point dot
    let last = CGPoint(x: px(cap-1), y: py(history.last!))
    col.setFill(); NSBezierPath(ovalIn: NSRect(x: last.x-2.5, y: last.y-2.5, width: 5, height: 5)).fill()
    // ---- footer: battery / ssd ----
    let div = NSBezierPath(); div.move(to: CGPoint(x: L, y: 24)); div.line(to: CGPoint(x: W - 14, y: 24))
    NSColor.separatorColor.setStroke(); div.lineWidth = 0.5; div.stroke()
    let bold = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
    var fx: CGFloat = L
    func kv(_ k: String, _ v: Double) {
      text(k, fx, 6, small, dim); fx += (k as NSString).size(withAttributes: [.font: small]).width + 4
      let vs = String(format: "%.0f°", v); text(vs, fx, 5, bold, txt)
      fx += (vs as NSString).size(withAttributes: [.font: bold]).width + 18
    }
    if let b = s.battery { kv("Battery", b) }
    if let d = s.ssd { kv("SSD", d) }
  }
}

/// Custom toggle: NSSwitch does not paint its accent tint inside menu-item views on recent macOS,
/// so we draw a look-alike ourselves.
final class Toggle: NSView {
  var isOn = false { didSet { needsDisplay = true } }
  var onChange: ((Bool) -> Void)?
  override var intrinsicContentSize: NSSize { NSSize(width: 38, height: 22) }
  override func mouseDown(with e: NSEvent) { isOn.toggle(); onChange?(isOn) }
  override func draw(_ r: NSRect) {
    let track = NSBezierPath(roundedRect: bounds, xRadius: bounds.height/2, yRadius: bounds.height/2)
    (isOn ? NSColor.controlAccentColor : NSColor.tertiaryLabelColor.withAlphaComponent(0.35)).setFill(); track.fill()
    let d = bounds.height - 4
    let x = isOn ? bounds.width - d - 2 : 2
    let knob = NSBezierPath(ovalIn: NSRect(x: x, y: 2, width: d, height: d))
    NSColor.white.setFill(); knob.fill()
  }
}

final class App: NSObject, NSApplicationDelegate, NSMenuDelegate {
  let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  let menu = NSMenu()
  let panel = Panel(frame: NSRect(x: 0, y: 0, width: 260, height: 168))
  let loginSwitch = Toggle(frame: NSRect(x: 0, y: 0, width: 38, height: 22))
  let loginLabel = NSTextField(labelWithString: "Launch at Login")
  var history: [Double] = []
  var timer: Timer?

  func applicationDidFinishLaunching(_ n: Notification) {
    let mi = NSMenuItem(); mi.view = panel
    menu.addItem(mi)
    menu.addItem(.separator())
    let row = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 30))
    let label = loginLabel
    label.font = .systemFont(ofSize: 13); label.frame = NSRect(x: 14, y: 7, width: 190, height: 17)
    loginSwitch.frame.origin = CGPoint(x: 260 - 14 - loginSwitch.frame.width, y: (30 - loginSwitch.frame.height) / 2)
    loginSwitch.onChange = { [weak self] on in self?.setLogin(on) }
    row.addSubview(label); row.addSubview(loginSwitch)
    let login = NSMenuItem(); login.view = row
    menu.addItem(login)
    menu.delegate = self
    menu.addItem(NSMenuItem(title: "Quit TempBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    item.menu = menu
    syncLoginUI()
    refresh()
    timer = Timer(timeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
    timer?.tolerance = 1
    RunLoop.main.add(timer!, forMode: .common)  // keep ticking while menu is open
  }

  // Login item handled via System Events (same list System Settings shows).
  // SMAppService.status is unreliable for ad-hoc signed apps, so we use the visible list as the source of truth.
  func runAS(_ src: String) -> String? {
    var err: NSDictionary?
    let out = NSAppleScript(source: src)?.executeAndReturnError(&err)
    return err == nil ? (out?.stringValue ?? "") : nil
  }
  var loginEnabled: Bool {
    runAS(#"tell application "System Events" to return (name of every login item) contains "TempBar""#) == "true"
  }
  func setLogin(_ on: Bool) {
    let path = Bundle.main.bundlePath
    if on {
      _ = runAS("tell application \"System Events\" to make login item at end with properties {path:\"\(path)\", hidden:true}")
    } else {
      _ = runAS(#"tell application "System Events" to delete (every login item whose name is "TempBar")"#)
    }
    syncLoginUI()
  }

  func syncLoginUI() { loginSwitch.isOn = loginEnabled }

  func menuWillOpen(_ menu: NSMenu) { syncLoginUI() }

  func refresh() {
    guard let s = Summary.current() else { item.button?.title = "--°"; return }
    history.append(s.socMax); if history.count > 100 { history.removeFirst() }
    panel.history = history; panel.summary = s; panel.needsDisplay = true
    let color: NSColor = s.socMax >= 90 ? .systemRed : s.socMax >= 75 ? .systemOrange : .labelColor
    item.button?.attributedTitle = NSAttributedString(
      string: String(format: "%.0f°", s.socMax),
      attributes: [.foregroundColor: color, .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)])
  }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = App()
app.delegate = delegate
app.run()
