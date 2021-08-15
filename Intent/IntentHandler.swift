import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
    func provideMessageOptionsCollection(for intent: ConfigurationIntent, searchTerm: String?, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        let identifiers: [NSString] = [
            "こんにちは",
            "ありがとう",
            "さようなら"
        ]
        let allIdentifiers = INObjectCollection(items: identifiers)
        completion(allIdentifiers, nil)
    }

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
}
