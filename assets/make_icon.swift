import AppKit
// Renders the TempBar app icon (rounded dark square, gradient thermometer, spark line)
func render(_ size: CGFloat) -> NSImage {
  let img = NSImage(size: NSSize(width: size, height: size))
  img.lockFocus()
  let s = size, r = s * 0.22
  let bg = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s), xRadius: r, yRadius: r)
  NSGradient(starting: NSColor(calibratedRed: 0.13, green: 0.14, blue: 0.19, alpha: 1),
             ending: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.09, alpha: 1))!.draw(in: bg, angle: -90)
  // spark line behind
  let pts: [CGFloat] = [0.42,0.40,0.46,0.43,0.52,0.47,0.55,0.60,0.53,0.58]
  let sp = NSBezierPath()
  for (i,v) in pts.enumerated() {
    let p = CGPoint(x: s*(0.16 + 0.68*CGFloat(i)/CGFloat(pts.count-1)), y: s*v*0.9)
    i == 0 ? sp.move(to: p) : sp.line(to: p)
  }
  NSColor(calibratedRed: 0.25, green: 0.55, blue: 1, alpha: 0.35).setStroke()
  sp.lineWidth = s*0.035; sp.lineJoinStyle = .round; sp.lineCapStyle = .round; sp.stroke()
  // thermometer
  let cx = s*0.5, tubeW = s*0.16, top = s*0.82, bulbR = s*0.14, bulbY = s*0.27
  let tube = NSBezierPath(roundedRect: NSRect(x: cx-tubeW/2, y: bulbY, width: tubeW, height: top-bulbY), xRadius: tubeW/2, yRadius: tubeW/2)
  let bulb = NSBezierPath(ovalIn: NSRect(x: cx-bulbR, y: bulbY-bulbR, width: bulbR*2, height: bulbR*2))
  NSColor(white: 1, alpha: 0.92).setFill(); tube.fill(); bulb.fill()
  // mercury
  let inner = tubeW*0.5, fillTop = s*0.62
  let merc = NSBezierPath(roundedRect: NSRect(x: cx-inner/2, y: bulbY, width: inner, height: fillTop-bulbY), xRadius: inner/2, yRadius: inner/2)
  let mbulb = NSBezierPath(ovalIn: NSRect(x: cx-bulbR*0.7, y: bulbY-bulbR*0.7, width: bulbR*1.4, height: bulbR*1.4))
  let g = NSGradient(starting: NSColor(calibratedRed: 1, green: 0.35, blue: 0.25, alpha: 1),
                     ending: NSColor(calibratedRed: 1, green: 0.62, blue: 0.2, alpha: 1))!
  g.draw(in: mbulb, angle: 90); g.draw(in: merc, angle: 90)
  // ticks
  NSColor(white: 0.1, alpha: 0.35).setStroke()
  for k in 0..<4 {
    let y = s*(0.45 + 0.09*CGFloat(k)), t = NSBezierPath()
    t.move(to: CGPoint(x: cx+tubeW*0.15, y: y)); t.line(to: CGPoint(x: cx+tubeW*0.42, y: y)); t.lineWidth = s*0.012; t.stroke()
  }
  img.unlockFocus()
  return img
}
let out = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
for sz in [16,32,64,128,256,512,1024] {
  let img = render(CGFloat(sz))
  let rep = NSBitmapImageRep(cgImage: img.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
  rep.size = NSSize(width: sz, height: sz)
  let png = rep.representation(using: .png, properties: [:])!
  let name = sz == 1024 ? "icon_512x512@2x.png" : sz == 64 ? "icon_32x32@2x.png" : "icon_\(sz)x\(sz).png"
  try! png.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
  if [16,128,256].contains(sz) { try! render(CGFloat(sz*2)).tiffRepresentation.flatMap { NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }?.write(to: URL(fileURLWithPath: "\(out)/icon_\(sz)x\(sz)@2x.png")) }
}
