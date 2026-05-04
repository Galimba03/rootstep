import ActivityKit
import WidgetKit
import SwiftUI

// This must match EXACTLY the struct defined in AppDelegate.swift
public struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var time: String
        var distance: Double
        var pace: String
        var startTimeMs: Int64
        var isPaused: Bool
    }
    var workoutName: String
}

struct RootStepWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // Lock screen / Banner UI
            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color(red: 0.17, green: 0.49, blue: 0.20)) // Dark green
                    Text("ROOTSTEP")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.17, green: 0.49, blue: 0.20))
                    
                    Spacer()
                    
                    Image(systemName: "figure.run")
                        .foregroundColor(.gray)
                }
                
                // Main Stats (Distance and Time)
                HStack(alignment: .bottom) {
                    // Distance
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.2f", context.state.distance / 1000))
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("km")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Time & Pace
                    VStack(alignment: .trailing, spacing: 0) {
                        
                        // Native Apple Timer vs Static Time
                        if context.state.isPaused {
                            Text(context.state.time)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        } else {
                            let startDate = Date(timeIntervalSince1970: Double(context.state.startTimeMs) / 1000.0)
                            Text(startDate, style: .timer)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        
                        Text("Pace: \(context.state.pace)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                
                // Root Growth Progress Bar (loops every 1km)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.17, green: 0.49, blue: 0.20).opacity(0.2))
                            .frame(height: 10)
                        
                        // Calculate progress for current kilometer
                        let distanceInKm = context.state.distance / 1000
                        let progress = distanceInKm.truncatingRemainder(dividingBy: 1.0)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.17, green: 0.49, blue: 0.20))
                            .frame(width: max(0, min(CGFloat(progress) * geometry.size.width, geometry.size.width)), height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(16)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (quando tieni premuto a lungo) - Invariata, va bene così
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "leaf.fill").foregroundColor(.green)
                        Text(String(format: "%.2f km", context.state.distance / 1000))
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(context.state.time).font(.headline).monospacedDigit()
                    } else {
                        let startDate = Date(timeIntervalSince1970: Double(context.state.startTimeMs) / 1000.0)
                        Text(startDate, style: .timer).font(.headline).monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Pace: \(context.state.pace)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            } compactLeading: { 
                // Show the icon AND kilometres
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text(String(format: "%.2f km", context.state.distance / 1000))
                        .monospacedDigit()
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            } compactTrailing: {
                // Compact UI (small time on the right) - Invariata, ma ora lo spazio è più bilanciato
                if context.state.isPaused {
                    Text(context.state.time)
                        .monospacedDigit()
                        .foregroundColor(.green)
                } else {
                    let startDate = Date(timeIntervalSince1970: Double(context.state.startTimeMs) / 1000.0)
                    Text(startDate, style: .timer)
                        .monospacedDigit()
                        .foregroundColor(.green)
                }
            } minimal: {
                // Minimal UI (quando ci sono più app attive nella Dynamic Island) - Invariata
                Image(systemName: "leaf.fill").foregroundColor(.green)
            }
        }
    }
}