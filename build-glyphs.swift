// Rasterize real half-width katakana and digits for the self-contained shader.
import Foundation
import CoreGraphics
import CoreText

let symbols = Array("ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789")
let font = CTFontCreateWithName("HiraginoSans-W2" as CFString, 18, nil)
var words: [String] = []
for symbol in symbols {
    var pixels = [UInt8](repeating: 0, count: 12 * 22)
    pixels.withUnsafeMutableBytes { data in
        let ctx = CGContext(data: data.baseAddress, width: 12, height: 22,
            bitsPerComponent: 8, bytesPerRow: 12, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0)!
        let text = NSAttributedString(string: String(symbol), attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 1, alpha: 1)
        ])
        let line = CTLineCreateWithAttributedString(text)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        ctx.textPosition = CGPoint(x: (12 - bounds.width) / 2 - bounds.minX,
                                   y: (22 - bounds.height) / 2 - bounds.minY)
        CTLineDraw(line, ctx)
    }
    for pair in 0..<11 {
        var word: UInt32 = 0
        for y in 0..<2 {
            for x in 0..<12 where pixels[(pair * 2 + y) * 12 + x] > 100 {
                word |= UInt32(1) << UInt32(y * 12 + x)
            }
        }
        words.append(String(word) + "u")
    }
}
print("// Real mirrored half-width katakana and digits, rasterized with CoreText.")
print("const uint MATRIX_GLYPHS[\(words.count)] = uint[\(words.count)](\n" + words.joined(separator: ",") + ");")
print("""
float matrixGlyphPixel(ivec2 pixel, int glyphIndex) {
    if (pixel.x < 0 || pixel.x >= 12 || pixel.y < 0 || pixel.y >= 22) return 0.0;
    uint rowPair = MATRIX_GLYPHS[glyphIndex * 11 + pixel.y / 2];
    uint bit = uint((pixel.y - (pixel.y / 2) * 2) * 12 + pixel.x);
    return float((rowPair >> bit) & 1u);
}
float matrixGlyph(vec2 p, int glyphIndex) {
    // Mirrored light katakana, interpolated for smooth phosphor strokes.
    vec2 samplePoint = vec2(1.0 - p.x, p.y) * vec2(12.0, 22.0) - 0.5;
    ivec2 pixel = ivec2(floor(samplePoint));
    vec2 blend = fract(samplePoint);
    float top = mix(matrixGlyphPixel(pixel, glyphIndex),
                    matrixGlyphPixel(pixel + ivec2(1, 0), glyphIndex), blend.x);
    float bottom = mix(matrixGlyphPixel(pixel + ivec2(0, 1), glyphIndex),
                       matrixGlyphPixel(pixel + ivec2(1, 1), glyphIndex), blend.x);
    return mix(top, bottom, blend.y);
}
""")
