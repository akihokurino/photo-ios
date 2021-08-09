import Combine
import Photos
import UIKit

typealias PhotoAuthorizationStatus = PHAuthorizationStatus
typealias PhotosImageResponse = UIImage?

struct PhotosManager {
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
            fetchOptions.fetchLimit = 500
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

    static func requestFullImage(asset: Asset, deliveryMode: PHImageRequestOptionsDeliveryMode) -> Future<PhotosImageResponse, Never> {
        return Future<UIImage?, Never> { promise in
            let options = PHImageRequestOptions()
            options.deliveryMode = deliveryMode
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
