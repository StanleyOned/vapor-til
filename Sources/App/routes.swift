import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // POST
    router.post("api", "acronyms") { req -> Future<Acronym> in
        // Decode the request’s JSON into an Acronym
        return try req.content.decode(Acronym.self)
            // use flatMap(to:) to extract the acronym when decoding completes
            .flatMap(to: Acronym.self, { (acronym) in
                // Save the model using Fluent
                return acronym.save(on: req)
            })
    }
    // GET
    //1 Register a new route handler for the request, this return a Future [Acronym] object.
    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        //2 Perform query to all the acronyms
        // This is equivalent to the SQL query SELECT * FROM Acronyms
        return Acronym.query(on: req).all()
    }
    // GET with ID / parameter
    // Register a route at /api/acronyms/<ID> to handle a GET request
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        
        return try req.parameters.next(Acronym.self)
    }
    // PUT
    // Register a route for a PUT request to /api/acronyms/<ID> that returns
    // Future<Acronym>
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        // Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete. This provides both the acronym from the database and acronym from the request body to the closure
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) {
                            acronym, updatedAcronym in
                        
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            
                            return acronym.save(on: req)
        }
    }
    // DELETE
    // Register a route for a DELETE request to /api/acronyms/<ID> that returns
    // Future<HTTPStatus>
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        // Extract the acronym to delete from the request’s parameters.
        return try req.parameters.next(Acronym.self)
            //
            .delete(on: req)
            // Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return
            .transform(to: HTTPStatus.noContent)
    }
    
    handleSearchRequest(router: router)
    handleFirstRequest(router: router)
    sortAcronymRequest(router: router)
}

func sortAcronymRequest(router: Router) {
    
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        
        return Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
}

func handleSearchRequest(router: Router) {
    //SEARCH
    // Register a new route handler for /api/acronyms/search that returns
    // Future<[Acronym]>
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        // Retrieve the search term from the URL query string
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        // Use group to find all acronyms whose short and long property matches the searchTerm
        return Acronym.query(on: req).group(.or, closure: { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }).all()
    }
}

func handleFirstRequest(router: Router) {
    // Register a new HTTP GET route for /api/acronyms/first that returns
    // Future<Acronym>.
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        // Perform a query to get the first acronym. Use the map(to:) function to unwrap the
        // result of the query
        return Acronym.query(on: req).first().map(to: Acronym.self, { acronym  in
            
            // Ensure an acronym exists. first() returns an optional as there may be no acronyms
            // in the database. Throw a 404 Not Found error if no acronym is returned.
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        })
    }
}
