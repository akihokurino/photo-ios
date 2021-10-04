import Combine
import Photos
import UIKit

typealias PhotoAuthorizationStatus = PHAuthorizationStatus
typealias PhotosImageResponse = UIImage?

enum PhotosManager {
    static func requestAuthorization() -> Future<PhotoAuthorizationStatus, Never> {
        return Future<PhotoAuthorizationStatus, Never> { promise in
            PHPhotoLibrary.requestAuthorization { status in
                promise(.success(status))
            }
        }
    }

    static func fetchAssets() -> Future<[Asset], Never> {
        return Future<[Asset], Never> { promise in
            let fetchOptions = PHFetchOptions()
            fetchOptions.fetchLimit = 1000
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            let fetchResult: PHFetchResult = PHAsset.fetchAssets(
                with: .image,
                options: fetchOptions
            )
            var assets = [Asset]()
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(Asset(asset: asset))
            }
            promise(.success(assets))
        }
    }

    static func requestImage(asset: Asset, targetSize: CGSize) -> Future<PhotosImageResponse, Never> {
        return Future<UIImage?, Never> { promise in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager
                .default().requestImage(
                    for: asset.asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    promise(.success(image))
                }
        }
    }

    static func requestFullImage(asset: Asset) -> Future<PhotosImageResponse, Never> {
        return Future<UIImage?, Never> { promise in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager
                .default()
                .requestImage(
                    for: asset.asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    promise(.success(image))
                }
        }
    }
}

final class Asset: ObservableObject {
    let id: String
    let asset: PHAsset
    let manager = PHImageManager.default()
    
    @Published var image: UIImage? = nil

    func request(with targetSize: CGSize, callback: @escaping (UIImage?) -> Void) {
        guard self.image == nil else {
            callback(self.image)
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
                    callback(image)
                }
            }
        }
    }
    
    func requestForCrop(with targetSize: CGSize, callback: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        DispatchQueue.global().async {
            self.manager.requestImage(
                for: self.asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                DispatchQueue.main.async {
                    callback(image)
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
