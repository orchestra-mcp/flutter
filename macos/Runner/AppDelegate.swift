import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Return false so the app stays alive in the system tray when the window is closed.
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Retry a few times in case mainFlutterWindow isn't ready immediately.
    registerChannels()
  }

  private func registerChannels() {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      // Window not ready yet — retry after a short delay.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.registerChannels()
      }
      return
    }

    // Lifecycle channel
    let lifecycleChannel = FlutterMethodChannel(
      name: "com.orchestra.app/lifecycle",
      binaryMessenger: controller.engine.binaryMessenger
    )
    lifecycleChannel.setMethodCallHandler { (call, result) in
      if call.method == "activateApp" {
        NSApp.activate(ignoringOtherApps: true)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // File access channel — security-scoped bookmarks for sandbox
    let fileAccessChannel = FlutterMethodChannel(
      name: "com.orchestra.app/file_access",
      binaryMessenger: controller.engine.binaryMessenger
    )
    fileAccessChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleFileAccess(call: call, result: result)
    }
  }

  // MARK: - File Access Handlers

  private func handleFileAccess(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "checkDirectAccess":
      // Check if we can access ~/.orchestra/ directly (sandbox disabled).
      let home = FileManager.default.homeDirectoryForCurrentUser.path
      let orchestraDir = "\(home)/.orchestra"
      let canAccess = FileManager.default.isReadableFile(atPath: orchestraDir)
          || FileManager.default.isReadableFile(atPath: home)
      result(canAccess)

    case "requestFolderAccess":
      // Show NSOpenPanel and return a security-scoped bookmark.
      let args = call.arguments as? [String: Any]
      let message = args?["message"] as? String ?? "Select a folder to grant access"
      let initialPath = args?["initialPath"] as? String

      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = message
        panel.prompt = "Grant Access"

        if let path = initialPath {
          panel.directoryURL = URL(fileURLWithPath: path)
        }

        let response = panel.runModal()
        if response == .OK, let url = panel.url {
          // Create security-scoped bookmark
          do {
            let bookmarkData = try url.bookmarkData(
              options: .withSecurityScope,
              includingResourceValuesForKeys: nil,
              relativeTo: nil
            )
            result([
              "path": url.path,
              "bookmark": FlutterStandardTypedData(bytes: bookmarkData),
            ])
          } catch {
            result(FlutterError(
              code: "BOOKMARK_ERROR",
              message: "Failed to create bookmark: \(error.localizedDescription)",
              details: nil
            ))
          }
        } else {
          result(nil) // User cancelled
        }
      }

    case "resolveBookmark":
      // Resolve a saved bookmark to restore access across launches.
      guard let args = call.arguments as? [String: Any],
            let bookmarkData = (args["bookmark"] as? FlutterStandardTypedData)?.data else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing bookmark data", details: nil))
        return
      }

      do {
        var isStale = false
        let url = try URL(
          resolvingBookmarkData: bookmarkData,
          options: .withSecurityScope,
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )

        if url.startAccessingSecurityScopedResource() {
          // Bookmark resolved — access granted. We keep it open for the
          // lifetime of the app. stopAccessingSecurityScopedResource is
          // called automatically on app exit.
          var newBookmark: FlutterStandardTypedData? = nil
          if isStale {
            // Refresh the bookmark data
            if let refreshed = try? url.bookmarkData(
              options: .withSecurityScope,
              includingResourceValuesForKeys: nil,
              relativeTo: nil
            ) {
              newBookmark = FlutterStandardTypedData(bytes: refreshed)
            }
          }
          result([
            "path": url.path,
            "isStale": isStale,
            "newBookmark": newBookmark as Any,
          ])
        } else {
          result(FlutterError(
            code: "ACCESS_DENIED",
            message: "Security-scoped resource access denied",
            details: nil
          ))
        }
      } catch {
        result(FlutterError(
          code: "RESOLVE_ERROR",
          message: "Failed to resolve bookmark: \(error.localizedDescription)",
          details: nil
        ))
      }

    case "stopAccess":
      // Stop accessing a security-scoped resource.
      if let args = call.arguments as? [String: Any],
         let path = args["path"] as? String {
        let url = URL(fileURLWithPath: path)
        url.stopAccessingSecurityScopedResource()
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
