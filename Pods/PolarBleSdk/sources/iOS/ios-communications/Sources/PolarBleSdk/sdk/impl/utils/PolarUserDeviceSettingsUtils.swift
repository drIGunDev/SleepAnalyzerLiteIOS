//  Copyright © 2024 Polar. All rights reserved.

import Foundation
import RxSwift

public let DEVICE_SETTINGS_FILE_PATH = "/U/0/S/UDEVSET.BPB"
public let SENSOR_SETTINGS_FILE_PATH = "/UDEVSET.BPB"
private let TAG = "PolarUserDeviceSettingsUtils"

internal class PolarUserDeviceSettingsUtils {

    /// Read user device settings for the device
    static func getUserDeviceSettings(client: BlePsFtpClient, deviceSettingsPath: String) -> Single<PolarUserDeviceSettings.PolarUserDeviceSettingsResult> {
        BleLogger.trace(TAG, "getUserDeviceSettings")
        return Single<PolarUserDeviceSettings.PolarUserDeviceSettingsResult>.create { emitter in
            let operation = Protocol_PbPFtpOperation.with {
                $0.command = .get
                $0.path = deviceSettingsPath
            }
            let disposable = client.request(try! operation.serializedData()).subscribe(
                onSuccess: { response in
                    do {
                        let proto = try Data_PbUserDeviceSettings(serializedData: Data(response))
                        let result = PolarUserDeviceSettings.fromProto(pbUserDeviceSettings: proto)
                        emitter(.success(result))
                    } catch {
                        BleLogger.error("getUserDeviceSettings() failed for device: \(client), error: \(error).")
                        emitter(.failure(error))
                    }
                },
                onFailure: { error in
                    BleLogger.error("getUserDeviceSettings() failed for device: \(client), error: \(error).")
                    emitter(.failure(error))
                }
            )
            return Disposables.create {
                disposable.dispose()
            }
        }
    }
}
