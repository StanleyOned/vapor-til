import FluentPostgreSQL
import Vapor

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID
    
    var categories: Siblings<Acronym,
                            Category,
                            AcronymCategoryPivot> {
        return siblings()
    }
    
    init(short: String, long: String, userID: User.ID) {
        self.short = short
        self.long = long
        self.userID = userID
    }
}

extension Acronym: PostgreSQLModel {}
extension Acronym: Content {}
extension Acronym: Parameter {}

extension Acronym {
    var user: Parent<Acronym, User> {
        return parent(\.userID)
    }
}

extension Acronym: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // Create the table for Acronym in the database
        return Database.create(self, on: connection) { builder in
            // Use addProperties(to:) to add all the fields to the database. This means you don’t
            // need to add each column manually
            try addProperties(to: builder)
            // Add a reference between the userID property on Acronym and the id property on
            // User. This sets up the foreign key constraint between the two tables
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

