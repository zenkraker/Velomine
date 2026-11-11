using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRoutes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "routes");

            migrationBuilder.CreateTable(
                name: "routes",
                schema: "routes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    club_id = table.Column<Guid>(type: "uuid", nullable: true),
                    name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    surface = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    distance_m = table.Column<double>(type: "double precision", nullable: false),
                    climbing_m = table.Column<double>(type: "double precision", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_routes", x => x.id);
                    table.CheckConstraint("ck_routes_distance_m", "distance_m >= 0");
                    table.CheckConstraint("ck_routes_name", "char_length(btrim(name)) > 0");
                    table.CheckConstraint("ck_routes_surface", "surface IN ('road', 'gravel', 'mountain', 'mixed')");
                    table.ForeignKey(
                        name: "fk_routes_clubs_club_id",
                        column: x => x.club_id,
                        principalSchema: "clubs",
                        principalTable: "clubs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_routes_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "route_lines",
                schema: "routes",
                columns: table => new
                {
                    route_id = table.Column<Guid>(type: "uuid", nullable: false),
                    latitude = table.Column<double[]>(type: "double precision[]", nullable: false),
                    longitude = table.Column<double[]>(type: "double precision[]", nullable: false),
                    elevation = table.Column<float[]>(type: "real[]", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_route_lines", x => x.route_id);
                    table.CheckConstraint("ck_route_lines_aligned", "cardinality(latitude) = cardinality(longitude) AND (elevation IS NULL OR cardinality(elevation) = cardinality(latitude))");
                    table.CheckConstraint("ck_route_lines_points", "cardinality(latitude) >= 2");
                    table.ForeignKey(
                        name: "fk_route_lines_routes_route_id",
                        column: x => x.route_id,
                        principalSchema: "routes",
                        principalTable: "routes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_routes_club_id_created_at",
                schema: "routes",
                table: "routes",
                columns: new[] { "club_id", "created_at" });

            migrationBuilder.CreateIndex(
                name: "ix_routes_user_id_created_at",
                schema: "routes",
                table: "routes",
                columns: new[] { "user_id", "created_at" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "route_lines",
                schema: "routes");

            migrationBuilder.DropTable(
                name: "routes",
                schema: "routes");
        }
    }
}
