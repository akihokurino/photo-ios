import Intents

extension ConfigurationIntent {
    var interval: Int {
        switch self.minutesInterval {
        case MinutesInterval.unknown:
            return 1
        case MinutesInterval.one:
            return 1
        case MinutesInterval.five:
            return 5
        case MinutesInterval.ten:
            return 10
        case MinutesInterval.fifteen:
            return 15
        }
    }
}
