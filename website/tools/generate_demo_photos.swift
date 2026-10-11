// 生成官网在线体验和截图用的演示照片（插画风格，带拍摄时间 EXIF）。
// 用法：swift website/tools/generate_demo_photos.swift website/assets/demo
import AppKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

let out = CommandLine.arguments[1]
let W = 900, H = 1200

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
  CGColor(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
          blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func canvas(_ w: Int = W, _ h: Int = H, _ draw: (CGContext) -> Void) -> CGImage {
  let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  draw(ctx)
  return ctx.makeImage()!
}

func vGradient(_ ctx: CGContext, _ colors: [UInt32], _ rect: CGRect) {
  let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { rgb($0) } as CFArray, locations: nil)!
  ctx.saveGState(); ctx.clip(to: rect)
  ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: rect.maxY), end: CGPoint(x: 0, y: rect.minY), options: [])
  ctx.restoreGState()
}

func glow(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: UInt32, _ a: CGFloat = 0.6) {
  let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(color, a), rgb(color, 0)] as CFArray, locations: [0, 1])!
  ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
}

func ridge(_ ctx: CGContext, _ color: UInt32, base: CGFloat, amp: CGFloat, seed: Double, w: Int = W) {
  let p = CGMutablePath()
  p.move(to: CGPoint(x: 0, y: 0))
  var x: CGFloat = 0
  while x <= CGFloat(w) {
    let t = Double(x) / Double(w)
    let y = base + amp * CGFloat(sin(t * 5.3 + seed) * 0.5 + sin(t * 11.7 + seed * 2) * 0.25 + sin(t * 2.1 + seed * 3) * 0.6)
    p.addLine(to: CGPoint(x: x, y: y))
    x += 6
  }
  p.addLine(to: CGPoint(x: CGFloat(w), y: 0)); p.closeSubpath()
  ctx.setFillColor(rgb(color)); ctx.addPath(p); ctx.fillPath()
}

func peaks(_ ctx: CGContext, _ color: UInt32, _ pts: [(CGFloat, CGFloat)]) {
  let p = CGMutablePath()
  p.move(to: CGPoint(x: 0, y: 0))
  for (x, y) in pts { p.addLine(to: CGPoint(x: x, y: y)) }
  p.addLine(to: CGPoint(x: CGFloat(W), y: 0)); p.closeSubpath()
  ctx.setFillColor(rgb(color)); ctx.addPath(p); ctx.fillPath()
}

func blur(_ img: CGImage, _ radius: Double) -> CGImage {
  let ci = CIImage(cgImage: img).clampedToExtent().applyingGaussianBlur(sigma: radius).cropped(to: CGRect(x: 0, y: 0, width: img.width, height: img.height))
  return CIContext().createCGImage(ci, from: ci.extent)!
}

func text(_ ctx: CGContext, _ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor, bold: Bool = false) {
  let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
  NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
  NSAttributedString(string: s, attributes: [.font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size), .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
  NSGraphicsContext.restoreGraphicsState()
}

func rounded(_ ctx: CGContext, _ r: CGRect, _ radius: CGFloat, _ color: CGColor) {
  ctx.setFillColor(color); ctx.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)); ctx.fillPath()
}

// ---------- 场景 ----------

func sunsetMountains(_ shift: CGFloat = 0) -> CGImage {
  canvas { c in
    vGradient(c, [0xFFB36B, 0xF0745F, 0x8D4C8C, 0x2E2A5C], CGRect(x: 0, y: 0, width: W, height: H))
    glow(c, CGPoint(x: 600 + shift, y: 520), 380, 0xFFE0A0, 0.9)
    c.setFillColor(rgb(0xFFF1C9)); c.fillEllipse(in: CGRect(x: 545 + shift, y: 465, width: 110, height: 110))
    ridge(c, 0x6B3F78, base: 470, amp: 90, seed: 1 + Double(shift) / 200)
    ridge(c, 0x4A2E63, base: 360, amp: 70, seed: 3)
    ridge(c, 0x2B1E40, base: 220, amp: 50, seed: 5)
  }
}

func beach() -> CGImage {
  canvas { c in
    vGradient(c, [0xE8F6FF, 0x8FD3F5, 0x3FA8E0], CGRect(x: 0, y: 600, width: W, height: 600))
    glow(c, CGPoint(x: 200, y: 1000), 260, 0xFFFFFF, 0.8)
    vGradient(c, [0x1B8FC4, 0x2CB8D6, 0x66D9DF], CGRect(x: 0, y: 380, width: W, height: 220))
    c.setStrokeColor(rgb(0xFFFFFF, 0.5)); c.setLineWidth(5); c.setLineCap(.round)
    for i in 0..<6 {
      let y = CGFloat(400 + i * 34), x0 = CGFloat(60 + (i * 137) % 500)
      c.move(to: CGPoint(x: x0, y: y)); c.addLine(to: CGPoint(x: x0 + 160, y: y)); c.strokePath()
    }
    vGradient(c, [0xE9D3A6, 0xF6E6C4], CGRect(x: 0, y: 0, width: W, height: 380))
    let p = CGMutablePath(); p.move(to: CGPoint(x: 0, y: 380))
    p.addCurve(to: CGPoint(x: CGFloat(W), y: 330), control1: CGPoint(x: 300, y: 420), control2: CGPoint(x: 600, y: 300))
    p.addLine(to: CGPoint(x: CGFloat(W), y: 380)); p.closeSubpath()
    c.setFillColor(rgb(0xFFFFFF, 0.6)); c.addPath(p); c.fillPath()
    // 遮阳伞
    c.setFillColor(rgb(0x7A5230)); c.fill(CGRect(x: 640, y: 120, width: 10, height: 240))
    let u = CGMutablePath(); u.move(to: CGPoint(x: 520, y: 340))
    u.addQuadCurve(to: CGPoint(x: 770, y: 340), control: CGPoint(x: 645, y: 470)); u.closeSubpath()
    c.setFillColor(rgb(0xF25C54)); c.addPath(u); c.fillPath()
  }
}

func cityNight() -> CGImage {
  canvas { c in
    vGradient(c, [0x2A1B4D, 0x13173A, 0x070A1F], CGRect(x: 0, y: 0, width: W, height: H))
    c.setFillColor(rgb(0xFFFFFF, 0.8))
    for i in 0..<70 {
      let x = CGFloat((i * 197) % W), y = CGFloat(650 + (i * 89) % 550)
      c.fillEllipse(in: CGRect(x: x, y: y, width: 3, height: 3))
    }
    c.setFillColor(rgb(0xF4F1DE)); c.fillEllipse(in: CGRect(x: 650, y: 950, width: 90, height: 90))
    var x: CGFloat = 0, i = 0
    while x < CGFloat(W) {
      let bw = CGFloat(70 + (i * 53) % 90), bh = CGFloat(260 + (i * 131) % 380)
      c.setFillColor(rgb(i % 2 == 0 ? 0x1C2147 : 0x252A57)); c.fill(CGRect(x: x, y: 0, width: bw, height: bh))
      for wy in stride(from: 30, to: bh - 30, by: 38) {
        for wx in stride(from: 14, to: bw - 20, by: 26) where (Int(wx + wy) + i) % 3 != 0 {
          c.setFillColor(rgb(0xFFD27A, 0.85)); c.fill(CGRect(x: x + wx, y: wy, width: 12, height: 18))
        }
      }
      x += bw + 6; i += 1
    }
  }
}

func forest() -> CGImage {
  canvas { c in
    vGradient(c, [0xF4FBEF, 0xC9EBC3, 0x9ED6A0], CGRect(x: 0, y: 0, width: W, height: H))
    glow(c, CGPoint(x: 200, y: 1000), 300, 0xFFFFFF, 0.9)
    ridge(c, 0x7CC08A, base: 620, amp: 60, seed: 2)
    ridge(c, 0x4E9C6A, base: 480, amp: 70, seed: 4)
    for i in 0..<14 {
      let x = CGFloat(-20 + i * 70), h = CGFloat(240 + (i * 61) % 160), y = CGFloat(120 + (i * 37) % 90)
      let t = CGMutablePath(); t.move(to: CGPoint(x: x, y: y)); t.addLine(to: CGPoint(x: x + 50, y: y + h))
      t.addLine(to: CGPoint(x: x + 100, y: y)); t.closeSubpath()
      c.setFillColor(rgb(i % 2 == 0 ? 0x2F6F4E : 0x23593E)); c.addPath(t); c.fillPath()
    }
    c.setFillColor(rgb(0x1D4733)); c.fill(CGRect(x: 0, y: 0, width: W, height: 140))
  }
}

func desert() -> CGImage {
  canvas { c in
    vGradient(c, [0xFFE7C2, 0xFFC98A, 0xF3A15E], CGRect(x: 0, y: 0, width: W, height: H))
    c.setFillColor(rgb(0xFFF6E0)); c.fillEllipse(in: CGRect(x: 160, y: 820, width: 150, height: 150))
    glow(c, CGPoint(x: 235, y: 895), 300, 0xFFF3D0, 0.7)
    ridge(c, 0xE9A15F, base: 560, amp: 110, seed: 0.5)
    ridge(c, 0xD9874A, base: 420, amp: 120, seed: 2.5)
    ridge(c, 0xC0703A, base: 250, amp: 90, seed: 4.2)
  }
}

func aurora() -> CGImage {
  let base = canvas { c in
    vGradient(c, [0x0A2A3A, 0x08162B, 0x050A18], CGRect(x: 0, y: 0, width: W, height: H))
    c.setLineCap(.round)
    for (i, col) in [0x3CF2A6, 0x2BD9C9, 0x8A7CFF].enumerated() {
      c.setStrokeColor(rgb(UInt32(col), 0.55)); c.setLineWidth(CGFloat(90 - i * 20))
      let p = CGMutablePath(); p.move(to: CGPoint(x: -50, y: 700 + i * 60))
      p.addCurve(to: CGPoint(x: 950, y: 860 + i * 40), control1: CGPoint(x: 250, y: 1050), control2: CGPoint(x: 600, y: 600))
      c.addPath(p); c.strokePath()
    }
  }
  return canvas { c in
    c.draw(blur(base, 18), in: CGRect(x: 0, y: 0, width: W, height: H))
    c.setFillColor(rgb(0xFFFFFF, 0.85))
    for i in 0..<90 { c.fillEllipse(in: CGRect(x: CGFloat((i * 211 + i * i * 7) % W), y: CGFloat(300 + (i * 97 + i * i * 3) % 900), width: 3, height: 3)) }
    ridge(c, 0x0B1A22, base: 300, amp: 60, seed: 1.7)
    c.setFillColor(rgb(0x050C11)); c.fill(CGRect(x: 0, y: 0, width: W, height: 160))
  }
}

func lake() -> CGImage {
  canvas { c in
    vGradient(c, [0xE6F0FF, 0xB7CCF2, 0x8FA9E0], CGRect(x: 0, y: 600, width: W, height: 600))
    peaks(c, 0x5C6FA8, [(0, 600), (180, 880), (330, 740), (520, 960), (720, 760), (900, 860)])
    c.setFillColor(rgb(0xFFFFFF, 0.9))
    let snow = CGMutablePath(); snow.move(to: CGPoint(x: 470, y: 900)); snow.addLine(to: CGPoint(x: 520, y: 960)); snow.addLine(to: CGPoint(x: 572, y: 900)); snow.closeSubpath()
    c.addPath(snow); c.fillPath()
    vGradient(c, [0x7E95CC, 0x5C72AE, 0x40568F], CGRect(x: 0, y: 0, width: W, height: 600))
    c.setFillColor(rgb(0x6F84BF, 0.6))
    let r = CGMutablePath(); r.move(to: CGPoint(x: 0, y: 600))
    for (x, y) in [(180, 400), (330, 500), (520, 330), (720, 480), (900, 420)] as [(CGFloat, CGFloat)] { r.addLine(to: CGPoint(x: x, y: y)) }
    r.addLine(to: CGPoint(x: 900, y: 600)); r.closeSubpath(); c.addPath(r); c.fillPath()
    c.setStrokeColor(rgb(0xFFFFFF, 0.35)); c.setLineWidth(4)
    for i in 0..<8 { let y = CGFloat(80 + i * 60); c.move(to: CGPoint(x: CGFloat(80 + i * 70 % 400), y: y)); c.addLine(to: CGPoint(x: CGFloat(260 + i * 70 % 400), y: y)); c.strokePath() }
  }
}

func snow() -> CGImage {
  canvas { c in
    vGradient(c, [0xF7FAFF, 0xDCE7F7, 0xB9CBE6], CGRect(x: 0, y: 0, width: W, height: H))
    peaks(c, 0x9DB2D6, [(0, 500), (220, 860), (420, 620), (640, 980), (900, 640)])
    peaks(c, 0xFFFFFF, [(0, 420), (200, 640), (380, 520), (600, 720), (900, 470)])
    peaks(c, 0xE4ECF7, [(0, 260), (300, 380), (600, 300), (900, 360)])
    c.setFillColor(rgb(0x3E5B4A))
    for i in 0..<7 {
      let x = CGFloat(60 + i * 120), y: CGFloat = 220
      let t = CGMutablePath(); t.move(to: CGPoint(x: x, y: y)); t.addLine(to: CGPoint(x: x + 30, y: y + 120)); t.addLine(to: CGPoint(x: x + 60, y: y)); t.closeSubpath()
      c.addPath(t); c.fillPath()
    }
  }
}

func fields() -> CGImage {
  canvas { c in
    vGradient(c, [0xFFF3D6, 0xFFD8A8, 0xF7B7A3], CGRect(x: 0, y: 500, width: W, height: 700))
    c.setFillColor(rgb(0xFFF8E6)); c.fillEllipse(in: CGRect(x: 380, y: 520, width: 140, height: 140))
    glow(c, CGPoint(x: 450, y: 590), 320, 0xFFE9B5, 0.8)
    let cols: [UInt32] = [0xE8C15A, 0xC9A43F, 0xA4B85A, 0x7FA14A, 0x5E8A3E]
    for (i, col) in cols.enumerated() {
      let top = CGFloat(560 - i * 115)
      let p = CGMutablePath(); p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 0, y: top))
      p.addCurve(to: CGPoint(x: CGFloat(W), y: top - 20), control1: CGPoint(x: 300, y: top + 40), control2: CGPoint(x: 600, y: top - 50))
      p.addLine(to: CGPoint(x: CGFloat(W), y: 0)); p.closeSubpath()
      c.setFillColor(rgb(col)); c.addPath(p); c.fillPath()
    }
  }
}

func flowers() -> CGImage {
  canvas { c in
    vGradient(c, [0x2E6B3F, 0x4F8F4A, 0x8CC06B], CGRect(x: 0, y: 0, width: W, height: H))
    let petals: [UInt32] = [0xF25C8A, 0xFF8FB1, 0xFFD166, 0xF7F7F7, 0xC77DFF]
    for i in 0..<42 {
      let x = CGFloat((i * 173) % (W - 60) + 30), y = CGFloat((i * 271) % (H - 80) + 40)
      let r = CGFloat(26 + (i * 7) % 22)
      c.setFillColor(rgb(petals[i % petals.count]))
      for k in 0..<5 {
        let a = Double(k) / 5 * .pi * 2
        c.fillEllipse(in: CGRect(x: x + CGFloat(cos(a)) * r * 0.7 - r / 2, y: y + CGFloat(sin(a)) * r * 0.7 - r / 2, width: r, height: r))
      }
      c.setFillColor(rgb(0xFFE08A)); c.fillEllipse(in: CGRect(x: x - r / 3, y: y - r / 3, width: r / 1.5, height: r / 1.5))
    }
  }
}

func cityDay() -> CGImage {
  canvas { c in
    vGradient(c, [0xEAF4FF, 0xB9DCF7, 0x82BFEA], CGRect(x: 0, y: 0, width: W, height: H))
    c.setFillColor(rgb(0xFFFFFF, 0.9))
    for (x, y, w) in [(120, 1000, 220), (560, 1060, 180), (380, 900, 140)] as [(CGFloat, CGFloat, CGFloat)] {
      c.fillEllipse(in: CGRect(x: x, y: y, width: w, height: w * 0.35))
      c.fillEllipse(in: CGRect(x: x + w * 0.25, y: y + 15, width: w * 0.5, height: w * 0.4))
    }
    var x: CGFloat = 0, i = 0
    while x < CGFloat(W) {
      let bw = CGFloat(80 + (i * 47) % 70), bh = CGFloat(300 + (i * 113) % 420)
      c.setFillColor(rgb([0xD5E3F0, 0xBCD0E6, 0xA6BFDB][i % 3])); c.fill(CGRect(x: x, y: 0, width: bw, height: bh))
      c.setFillColor(rgb(0x8FB0D4, 0.6))
      for wy in stride(from: 24, to: bh - 24, by: 40) { c.fill(CGRect(x: x + 12, y: wy, width: bw - 24, height: 10)) }
      x += bw + 8; i += 1
    }
  }
}

func darkShot() -> CGImage {
  canvas { c in
    vGradient(c, [0x0B0B0D, 0x141418, 0x0A0A0B], CGRect(x: 0, y: 0, width: W, height: H))
    glow(c, CGPoint(x: 700, y: 950), 260, 0x3A2F2A, 0.6)
    c.setFillColor(rgb(0xFFFFFF, 0.04))
    for i in 0..<400 { c.fill(CGRect(x: CGFloat((i * 331) % W), y: CGFloat((i * 577) % H), width: 2, height: 2)) }
  }
}

func chatScreenshot() -> CGImage {
  canvas(900, 1950) { c in
    c.setFillColor(rgb(0xF2F2F7)); c.fill(CGRect(x: 0, y: 0, width: 900, height: 1950))
    c.setFillColor(rgb(0xFFFFFF)); c.fill(CGRect(x: 0, y: 1740, width: 900, height: 210))
    text(c, "9:41", 70, 1870, 34, .black, bold: true)
    text(c, "周末出游群（5）", 300, 1770, 38, .black, bold: true)
    let msgs: [(Bool, String, CGFloat)] = [(false, "周六几点出发？", 1580), (true, "早上 8 点，地铁站集合", 1440), (false, "收到 👌", 1310), (false, "记得带防晒", 1180), (true, "好的，我带零食", 1040), (false, "[图片]", 900), (true, "哈哈这张拍得好", 760)]
    for (me, s, y) in msgs {
      let w = CGFloat(s.count * 34 + 70)
      let x: CGFloat = me ? 900 - w - 50 : 130
      if !me { c.setFillColor(rgb(0xC7C7CC)); c.fillEllipse(in: CGRect(x: 40, y: y, width: 70, height: 70)) }
      rounded(c, CGRect(x: x, y: y, width: w, height: 90), 28, me ? rgb(0x95EC69) : rgb(0xFFFFFF))
      text(c, s, x + 35, y + 25, 32, .black)
    }
    c.setFillColor(rgb(0xFFFFFF)); c.fill(CGRect(x: 0, y: 0, width: 900, height: 170))
    rounded(c, CGRect(x: 40, y: 50, width: 820, height: 80), 20, rgb(0xF2F2F7))
  }
}

func receiptScreenshot() -> CGImage {
  canvas(900, 1950) { c in
    c.setFillColor(rgb(0xF5F6F8)); c.fill(CGRect(x: 0, y: 0, width: 900, height: 1950))
    text(c, "9:41", 70, 1870, 34, .black, bold: true)
    rounded(c, CGRect(x: 60, y: 820, width: 780, height: 880), 36, rgb(0xFFFFFF))
    c.setFillColor(rgb(0x34C759)); c.fillEllipse(in: CGRect(x: 390, y: 1480, width: 120, height: 120))
    c.setStrokeColor(rgb(0xFFFFFF)); c.setLineWidth(12); c.setLineCap(.round); c.setLineJoin(.round)
    c.move(to: CGPoint(x: 420, y: 1540)); c.addLine(to: CGPoint(x: 445, y: 1512)); c.addLine(to: CGPoint(x: 485, y: 1565)); c.strokePath()
    text(c, "支付成功", 360, 1400, 44, .black, bold: true)
    text(c, "¥ 128.00", 330, 1290, 64, .black, bold: true)
    let rows = [("商户", "街角咖啡店"), ("时间", "2026-08-21 09:12"), ("方式", "零钱"), ("单号", "4200 0026 8812 0931")]
    for (i, r) in rows.enumerated() {
      let y = CGFloat(1190 - i * 70)
      text(c, r.0, 120, y, 30, .gray); text(c, r.1, 420, y, 30, .black)
    }
    rounded(c, CGRect(x: 120, y: 860, width: 660, height: 90), 45, rgb(0x34C759, 0.15))
    text(c, "完成", 415, 880, 36, NSColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1), bold: true)
  }
}

// ---------- 输出 ----------

func save(_ img: CGImage, _ name: String, _ date: String) {
  let url = URL(fileURLWithPath: "\(out)/\(name).jpg")
  let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
  let props: [CFString: Any] = [
    kCGImageDestinationLossyCompressionQuality: 0.82,
    kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: date, kCGImagePropertyExifDateTimeDigitized: date],
    kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFDateTime: date],
  ]
  CGImageDestinationAddImage(dest, img, props as CFDictionary)
  CGImageDestinationFinalize(dest)
}

let sunset = sunsetMountains()
let photos: [(String, CGImage, String)] = [
  ("01-sunset", sunset, "2026:09:28 18:42:10"),
  ("02-sunset-dup", sunsetMountains(18), "2026:09:28 18:42:13"),
  ("03-sunset-blur", blur(sunset, 14), "2026:09:28 18:42:15"),
  ("04-chat", chatScreenshot(), "2026:09:20 21:05:00"),
  ("05-beach", beach(), "2026:08:16 15:20:00"),
  ("06-receipt", receiptScreenshot(), "2026:08:21 09:12:30"),
  ("07-city-night", cityNight(), "2026:08:09 22:10:00"),
  ("08-dark", darkShot(), "2026:07:30 20:01:00"),
  ("09-forest", forest(), "2026:07:12 10:30:00"),
  ("10-desert", desert(), "2026:07:03 17:45:00"),
  ("11-aurora", aurora(), "2026:06:18 23:50:00"),
  ("12-flowers", flowers(), "2026:05:02 11:20:00"),
  ("13-lake", lake(), "2026:04:11 08:15:00"),
  ("14-fields", fields(), "2026:03:22 07:05:00"),
  ("15-snow", snow(), "2026:01:15 13:30:00"),
  ("16-city-day", cityDay(), "2025:11:08 14:00:00"),
]
for (n, img, d) in photos { save(img, n, d) }
print("ok \(photos.count)")
