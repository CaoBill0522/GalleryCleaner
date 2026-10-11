// 生成应用图标：纯黑底 + 白色扁平图形（照片 + 扫帚）。
// 用法：swift assets/icon/generate_icon.swift assets/icon
import AppKit

let out = CommandLine.arguments[1]
let S: CGFloat = 1024
let white = NSColor.white
let black = NSColor.black

func drawBackground() {
  black.setFill()
  NSRect(x: 0, y: 0, width: S, height: S).fill()
}

func drawForeground(scale: CGFloat) {
  let ctx = NSGraphicsContext.current!.cgContext
  ctx.saveGState()
  ctx.translateBy(x: S / 2, y: S / 2)
  ctx.scaleBy(x: scale, y: scale)
  ctx.translateBy(x: -S / 2 - 24, y: -S / 2 + 40)

  // 照片：白色圆角方块，略微向左倾斜
  ctx.saveGState()
  ctx.translateBy(x: 470, y: 560)
  ctx.rotate(by: 0.08)
  let card = NSRect(x: -230, y: -230, width: 460, height: 460)
  white.setFill()
  NSBezierPath(roundedRect: card, xRadius: 96, yRadius: 96).fill()
  // 镂空的山和太阳
  black.setFill(); black.setStroke()
  let m = NSBezierPath()
  m.move(to: NSPoint(x: -150, y: -130))
  m.line(to: NSPoint(x: -40, y: 10))
  m.line(to: NSPoint(x: 25, y: -60))
  m.line(to: NSPoint(x: 70, y: -15))
  m.line(to: NSPoint(x: 150, y: -130))
  m.close()
  m.lineJoinStyle = .round; m.lineWidth = 26
  m.fill(); m.stroke()
  NSBezierPath(ovalIn: NSRect(x: 52, y: 70, width: 82, height: 82)).fill()
  ctx.restoreGState()

  // 扫帚：右下角，斜着扫
  ctx.saveGState()
  ctx.translateBy(x: 668, y: 268)
  ctx.rotate(by: -0.6)
  ctx.scaleBy(x: 0.9, y: 0.9)
  white.setFill()
  NSBezierPath(roundedRect: NSRect(x: -16, y: 50, width: 32, height: 330), xRadius: 16, yRadius: 16).fill()
  NSBezierPath(roundedRect: NSRect(x: -56, y: 22, width: 112, height: 44), xRadius: 14, yRadius: 14).fill()
  let br = NSBezierPath()
  br.move(to: NSPoint(x: -54, y: 18))
  br.line(to: NSPoint(x: 54, y: 18))
  br.line(to: NSPoint(x: 96, y: -128))
  br.curve(to: NSPoint(x: -96, y: -128), controlPoint1: NSPoint(x: 40, y: -138), controlPoint2: NSPoint(x: -40, y: -138))
  br.close()
  br.fill()
  // 刷毛缝隙
  black.setStroke()
  for x in stride(from: -40.0, through: 40.0, by: 40.0) {
    let l = NSBezierPath()
    l.move(to: NSPoint(x: x * 0.7, y: -10)); l.line(to: NSPoint(x: x * 1.5, y: -122))
    l.lineWidth = 12; l.lineCapStyle = .round; l.stroke()
  }
  ctx.restoreGState()

  // 被扫走的小照片
  white.setFill()
  for (x, y, s) in [(452.0, 214.0, 34.0), (392.0, 248.0, 24.0), (342.0, 210.0, 16.0)] as [(CGFloat, CGFloat, CGFloat)] {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: s, height: s), xRadius: s * 0.25, yRadius: s * 0.25).fill()
  }
  ctx.restoreGState()
}

func render(_ name: String, bg: Bool, fg: Bool, scale: CGFloat) {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8,
                             samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  if bg { drawBackground() }
  if fg { drawForeground(scale: scale) }
  NSGraphicsContext.restoreGraphicsState()
  try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}

render("icon.png", bg: true, fg: true, scale: 1)
render("icon_foreground.png", bg: false, fg: true, scale: 0.68)
render("icon_background.png", bg: true, fg: false, scale: 1)
