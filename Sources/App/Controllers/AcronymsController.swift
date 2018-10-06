import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        // GET all /api/acronyms
        acronymsRoutes.get(use: getAllHandler)
        // Post/Create /api/acronyms
        acronymsRoutes.post(Acronym.self, use: createHandler)
        // get with ID /api/acronyms/{ID}
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        // PUT/UPDATE /api/acronyms/{ID}
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        // DELETE /api/acronyms/{ID}
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        // Search /api/acronyms/search?term={string}
        acronymsRoutes.get("search", use: searchHandler)
        // GET first Acronym /api/acronyms/first
        acronymsRoutes.get("first", use: getFirstHandler)
        // GET Sorted Acronyms /api/acronyms/sorted
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        // GET This connects an HTTP GET request to /api/acronyms/<ID>/user to getUserHandler(_:)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        // This routes an HTTP POST request to /api/acronyms/<ACRONYM_ID>/categories/ <CATEGORY_ID>
        acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: addCategoryHandler)
        // /api/acronyms/<ACRONYM_ID>/categories
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        
        acronymsRoutes.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }
    // GET all acronyms
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    // Post
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
        return acronym.save(on: req)
    }
    // GET with ID / parameter
    // Register a route at /api/acronyms/<ID> to handle a GET request
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    // PUT
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self), {
                            acronym, updatedAcronym -> Future<Acronym> in
                            
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            acronym.userID = updatedAcronym.userID
                            return acronym.save(on: req)
        })
    }
    // DELETE
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        return try req
            .parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }
    
    // GET: Search Request
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req).group(.or, closure: { (or) in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }).all()
    }
    
    // GET first acronym
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        
        return Acronym.query(on: req).first().map(to: Acronym.self, { acronym  in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        })
    }
    
    // GET sorted Acronyms
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User> {
        
        return try req.parameters.next(Acronym.self).flatMap(to: User.self, { acronym in
            // Use the new computed property created above to get the acronym’s owner
            acronym.user.get(on: req)
        })
    }
    
    // Define a new route handler, addCategoriesHandler(_:), that returns a
    // Future<HTTPStatus>
    func addCategoryHandler(_ req: Request) throws -> Future<HTTPStatus> {
        // Use flatMap(to:_:_:) to extract both the acronym and category from the request’s
        // parameters.
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self), { acronym, category  in
            // Use attach(_:on:) to set up the relationship between acronym and category. This creates a pivot model and saves it in the database. Transform the result into a 201 Created response.
            return acronym.categories.attach(category, on: req).transform(to: .created)
        })
    }
    
    //
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        //
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self, { acronym in
            try acronym.categories.query(on: req).all()
        })
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self), { (acronym, category)  in
            
            return acronym.categories.detach(category, on: req).transform(to: .noContent)
        })
    }
}
