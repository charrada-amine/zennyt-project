import org.flywaydb.core.Flyway;

/** Local recovery helper using the existing backend dependency classpath. */
class MigrateLocalGames {
    public static void main(String[] args) {
        if (args.length != 1 || !args[0].matches("zennyt(?:_[a-z0-9_]+)?")) {
            throw new IllegalArgumentException("Provide the exact backed-up local zennyt database name");
        }
        var flyway = Flyway.configure()
            .dataSource("jdbc:postgresql://localhost:5432/" + args[0],
                System.getenv().getOrDefault("PGUSER", "postgres"),
                System.getenv().getOrDefault("PGPASSWORD", "postgres"))
            .locations("filesystem:backend/src/main/resources/db/migration")
            // One-off only: normal Spring startup retains strict validation.
            .outOfOrder(true)
            .load();
        var result = flyway.migrate();
        flyway.validate();
        System.out.println("Validated " + args[0] + "; migrations applied: " + result.migrationsExecuted);
    }
}
