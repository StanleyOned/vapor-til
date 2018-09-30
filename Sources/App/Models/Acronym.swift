import FluentPostgreSQL
import Vapor

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
    }
}

extension Acronym: Migration {}
extension Acronym: PostgreSQLModel {}
extension Acronym: Content {}
