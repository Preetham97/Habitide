import SwiftUI

@MainActor
enum ShareImageRenderer {
    static func render<V: View>(_ view: V, scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }
}
