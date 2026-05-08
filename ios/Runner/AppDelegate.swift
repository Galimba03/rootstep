import UIKit
import Flutter
import ActivityKit

// Data structure that we receive from Flutter
struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var time: String
        var distance: Double
        var pace: String
        var startTimeMs: Int64
        var isPaused: Bool
    }
    var workoutName: String
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // Variable to keep track of activity 
  var currentActivity: Any? = nil

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let registrar = self.registrar(forPlugin: "LiveActivityPlugin")!
    let liveActivityChannel = FlutterMethodChannel(
        name: "com.galimba.rootstep/live_activity",
        binaryMessenger: registrar.messenger()
    )

    liveActivityChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }

      if #available(iOS 16.1, *) {
          switch call.method {
          case "startActivity":
              self.startLiveActivity(call: call, result: result)
          case "updateActivity":
              self.updateLiveActivity(call: call, result: result)
          case "stopActivity":
              self.stopLiveActivity(result: result)
          default:
              result(FlutterMethodNotImplemented)
          }
      } else {
          result(FlutterError(code: "UNAVAILABLE", message: "Live Activities require iOS 16.1+", details: nil))
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /*
      Functions for Live Activity
  */
  @available(iOS 16.1, *)
  private func startLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? [String: Any],
            let time = args["time"] as? String,
            let distance = args["distance"] as? Double,
            let pace = args["pace"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
      }
      
      // Sent data for native cronometer.
      let startTimeMs = args["startTimeMs"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
      let isPaused = args["isPaused"] as? Bool ?? false

      // New state object.
      let state = WorkoutAttributes.ContentState(
          time: time, 
          distance: distance, 
          pace: pace, 
          startTimeMs: startTimeMs, 
          isPaused: isPaused
      )

      // Anti-duplication of the widget in the lock screen.
      if let activity = self.currentActivity as? Activity<WorkoutAttributes> {
          if activity.activityState == .active {
              Task {
                  await activity.update(using: state)
                  result(nil)
              }
              return
          } else {
              // Activity deleted from the user. Empty the variable
              self.currentActivity = nil
          }
      }

      let attributes = WorkoutAttributes(workoutName: "RootStep Run")

      do {
          if #available(iOS 16.2, *) {
              let activity = try Activity<WorkoutAttributes>.request(
                  attributes: attributes,
                  contentState: state,
                  pushType: nil
              )
              self.currentActivity = activity
          } else {
              let activity = try Activity<WorkoutAttributes>.request(
                  attributes: attributes,
                  contentState: state,
                  pushType: nil
              )
              self.currentActivity = activity
          }
          result(nil)
      } catch {
          print("ERRORE LIVE ACTIVITY: \(error.localizedDescription)") 
          result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
      }
  }

  @available(iOS 16.1, *)
  private func updateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? [String: Any],
            let time = args["time"] as? String,
            let distance = args["distance"] as? Double,
            let pace = args["pace"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
      }

      guard let activity = self.currentActivity as? Activity<WorkoutAttributes> else {
          result(FlutterError(code: "NO_ACTIVITY", message: "No active Live Activity", details: nil))
          return
      }

      if activity.activityState != .active {
          self.currentActivity = nil // Clean memory
          result(FlutterError(code: "NO_ACTIVITY", message: "Activity was killed by user", details: nil))
          return
      }

      let startTimeMs = args["startTimeMs"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
      let isPaused = args["isPaused"] as? Bool ?? false

      let state = WorkoutAttributes.ContentState(
          time: time, 
          distance: distance, 
          pace: pace, 
          startTimeMs: startTimeMs, 
          isPaused: isPaused
      )

      Task {
          await activity.update(using: state)
          result(nil)
      }
  }

  @available(iOS 16.1, *)
  private func stopLiveActivity(result: @escaping FlutterResult) {
      guard let activity = self.currentActivity as? Activity<WorkoutAttributes> else {
          result(nil)
          return
      }

      Task {
          await activity.end(using: nil, dismissalPolicy: .immediate)
          self.currentActivity = nil
          result(nil)
      }
  }
}