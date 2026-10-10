import Flutter
import UIKit
import AVFoundation
import AudioToolbox
import Network

/**
 * NativeSecurityPlugin provides real iOS hardware access for:
 * - AVCaptureDevice Flashlight / Torch
 * - Hardware Siren / Audio Alert via AudioToolbox & AVAudioSession
 * - Battery monitoring & Charging status via UIDevice
 * - Network Reachability / Airplane Mode via NWPathMonitor
 * - Front camera silent intruder selfie capture via AVCaptureSession
 */
public class NativeSecurityPlugin: NSObject, FlutterPlugin, AVCapturePhotoCaptureDelegate {

    public static let channelName = "com.security.antitheft.dont_touch_my_phone/native_security"

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var photoCompletion: ((String?) -> Void)?
    private let pathMonitor = NWPathMonitor()
    private var isNetworkConnected: Bool = true

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = NativeSecurityPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    override init() {
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        setupNetworkMonitor()
    }

    private func setupNetworkMonitor() {
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkConnected = (path.status == .satisfied)
        }
        pathMonitor.start(queue: queue)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hasFlash":
            let hasTorch = AVCaptureDevice.default(for: .video)?.hasTorch ?? false
            result(hasTorch)

        case "setFlash":
            guard let args = call.arguments as? [String: Any],
                  let on = args["on"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing 'on' boolean argument", details: nil))
                return
            }
            setTorch(on: on, result: result)

        case "playBeep":
            playSystemAlarm()
            result(true)

        case "stopBeep":
            // Stop sound if any active
            result(true)

        case "getBatteryLevel":
            let level = Int(UIDevice.current.batteryLevel * 100)
            result(level >= 0 ? level : -1)

        case "isCharging":
            let state = UIDevice.current.batteryState
            let charging = (state == .charging || state == .full)
            result(charging)

        case "isAirplaneModeOn":
            // On iOS, if no network path is available and cellular is off
            result(!isNetworkConnected)

        case "setMaxVolume":
            configureMaxAudioSession()
            result(true)

        case "captureIntruderPhoto":
            captureFrontCameraPhoto { photoPath in
                DispatchQueue.main.async {
                    if let path = photoPath {
                        result(path)
                    } else {
                        result(FlutterError(code: "CAPTURE_FAILED", message: "Failed capturing front selfie", details: nil))
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setTorch(on: Bool, result: @escaping FlutterResult) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            result(FlutterError(code: "NO_TORCH", message: "Device does not have a torch", details: nil))
            return
        }

        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
            result(true)
        } catch {
            result(FlutterError(code: "TORCH_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func playSystemAlarm() {
        configureMaxAudioSession()
        // Play emergency system sound with vibration
        AudioServicesPlayAlertSound(SystemSoundID(1005))
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func configureMaxAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch {}
    }

    private func captureFrontCameraPhoto(completion: @escaping (String?) -> Void) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus != .authorized {
            completion(nil)
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera),
              session.canAddInput(input) else {
            completion(nil)
            return
        }

        session.addInput(input)

        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            completion(nil)
            return
        }
        session.addOutput(output)

        self.captureSession = session
        self.photoOutput = output
        self.photoCompletion = completion

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureSession?.stopRunning()

        guard error == nil, let photoData = photo.fileDataRepresentation() else {
            photoCompletion?(nil)
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = paths.first else {
            photoCompletion?(nil)
            return
        }

        let fileURL = documentsDirectory.appendingPathComponent("INTRUDER_\(timestamp).jpg")

        do {
            try photoData.write(to: fileURL)
            photoCompletion?(fileURL.path)
        } catch {
            photoCompletion?(nil)
        }
    }
}
