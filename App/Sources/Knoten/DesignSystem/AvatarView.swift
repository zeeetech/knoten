import KnotenCore
import SwiftUI

/// Decoded avatars, so a list does not re-decode a two megapixel JPEG on every
/// scroll. The blob cache holds the bytes; this holds what came out of them.
@MainActor
final class AvatarImageCache {
    static let shared = AvatarImageCache()

    private let images = NSCache<NSString, UIImage>()

    init(countLimit: Int = 128) {
        images.countLimit = countLimit
    }

    func image(for key: String) -> UIImage? {
        images.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, for key: String) {
        images.setObject(image, forKey: key as NSString)
    }
}

struct AvatarView: View {
    let blob: BlobRef?
    let did: String
    let pds: URL
    let loader: BlobLoader
    var size: CGFloat = 44

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Theme.Palette.surfaceHigh)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.42))
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .task(id: blob?.cid) { await load() }
    }

    private func load() async {
        guard let blob else { return }

        let key = BlobLoader.key(did: did, cid: blob.cid)
        if let cached = AvatarImageCache.shared.image(for: key) {
            image = cached
            return
        }

        guard case .success(let data) = await loader.fetch(blob, did: did, pds: pds),
              let decoded = UIImage(data: data)
        else {
            return
        }

        let scaled = decoded.downscaled(to: size * displayScale)
        AvatarImageCache.shared.store(scaled, for: key)
        image = scaled
    }
}

private extension UIImage {
    /// `getBlob` hands back the original, which for an avatar can be a couple
    /// of megapixels. Decode once, shrink once, then keep the result.
    func downscaled(to longestSide: CGFloat) -> UIImage {
        let current = max(size.width, size.height)
        guard current > longestSide, current > 0 else { return self }

        let ratio = longestSide / current
        let target = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
