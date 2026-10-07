import Cocoa
import FlutterMacOS

final class LabBridge {
  private let nativeWindow = NativeWebWindow()
  private let channel: FlutterMethodChannel

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(name: "dev.dmilab.keylab", binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      let lab = KeyboardExperiment.shared
      switch call.method {
      case "configure":
        guard let args = call.arguments as? [String: String],
              let mode = args["mode"], let run = args["run"],
              lab.configure(id: mode, run: run) else {
          result(FlutterError(code: "restart_required", message: "Clean restart required after loop", details: nil))
          return
        }
        self.nativeWindow.close()
        (controller.view.window as? WebCommandWindow)?.webCommandScope.reset()
        result(nil)
      case "openNative":
        guard let value = call.arguments as? String, let url = URL(string: value),
              url.host == "127.0.0.1", url.scheme == "http" else {
          result(FlutterError(code: "invalid_url", message: "Expected local diagnostic URL", details: nil))
          return
        }
        self.nativeWindow.open(url: url)
        result(nil)
      case "snapshot":
        var snapshot = lab.snapshot
        snapshot["commandRouting"] = (controller.view.window as? WebCommandWindow)?.webCommandScope.snapshot
        result(snapshot)
      case "loadResults":
        result(UserDefaults.standard.string(forKey: "keyLabResults") ?? "{}")
      case "saveResults":
        if let value = call.arguments as? String {
          UserDefaults.standard.set(value, forKey: "keyLabResults")
        }
        result(nil)
      case "stop":
        lab.stop()
        self.nativeWindow.close()
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

}
