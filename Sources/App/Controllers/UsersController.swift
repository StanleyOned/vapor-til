
import Vapor

struct UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(User.self, use: createHandler)
        
        usersRoute.get(use: getAllHanlder)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    // POST
    func createHandler(_ req: Request, user: User) throws -> Future<User> {
        return user.save(on: req)
    }
    
    // GET all
    func getAllHanlder(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    // get with ID
    func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    // /api/users/<USER ID>/acronyms
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self) { user  in
            try user.acronyms.query(on: req).all()
        }
    }
}
