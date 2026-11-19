import Foundation

/// The timing of a sleep alarm's fades.
public enum SleepSchedule {
    /// When the fade in of [alarm] starts, as seen at [now], and how long it
    /// takes to reach full volume at the wake time.
    ///
    /// The wake time is the next one to come. If its fade in should already
    /// have started, it starts now and takes the time that's left; otherwise
    /// an alarm set to wake in a minute with a minute's fade in would wait a
    /// day.
    public static func wakeUp(_ alarm: SleepAlarm, now: Date, calendar: Calendar = .current)
        -> (fadeInAt: Date, fadeIn: TimeInterval)
    {
        let midnight = calendar.startOfDay(for: now)
        var wakeAt = calendar.date(byAdding: .minute, value: alarm.wakeTime, to: midnight)!
        if wakeAt <= now { wakeAt = calendar.date(byAdding: .day, value: 1, to: wakeAt)! }
        let fadeIn = TimeInterval(alarm.beforeEndTimeMin * 60)
        let fadeInAt = wakeAt.addingTimeInterval(-fadeIn)
        return fadeInAt > now ? (fadeInAt, fadeIn) : (now, wakeAt.timeIntervalSince(now))
    }

    /// The next fade volume after [volume], moving slower as it gets quieter
    /// unless [linear].
    public static func step(_ volume: Double, down: Bool, linear: Bool) -> Double {
        let step =
            linear ? 0.01 : volume > 0.67 ? 0.03 : volume > 0.4 ? 0.02 : 0.00533
        return min(max(down ? volume - step : volume + step, 0), 1)
    }
}
