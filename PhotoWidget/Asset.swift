import Combine
import Photos
import UIKit

final class Asset: ObservableObject {
    let id: String
    @Published var image: UIImage? = nil
    let asset: PHAsset
    private var manager = PHImageManager.default()

    func request(with targetSize: CGSize) {
        guard self.image == nil else {
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        DispatchQueue.global().async {
            self.manager.requestImage(
                for: self.asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
    }

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }
}

extension Asset: Identifiable, Hashable {
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension PHAsset: Identifiable {}
