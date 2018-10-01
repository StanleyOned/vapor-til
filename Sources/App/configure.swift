import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    /// Register the FluentSQLiteProvider as a service to allow the application to interact with SQLite via Fluent
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() 
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)

    // 1
    var databases = DatabasesConfig()
    //2
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    //3
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        port: 5432,
        username: username,
        database: databaseName,
        password: password,
        transport: .cleartext)
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)

    /// Configure migrations
    /// Tells which database to use for the models of Acronym
    var migrations = MigrationConfig()
    migrations.add(model: Acronym.self, database: .psql)
    services.register(migrations)

}
