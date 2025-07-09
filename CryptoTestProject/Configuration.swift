import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

extension Configuration {
    static var coinGeckoAPIKey: String {
        return (try? Configuration.value(for: "COINGECKO_API_KEY")) ?? ""
    }
    
    static var supabaseURL: String {
        return (try? Configuration.value(for: "SUPABASE_URL")) ?? ""
    }
    
    static var supabaseKey: String {
        return (try? Configuration.value(for: "SUPABASE_KEY")) ?? ""
    }
} 