using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class ZoneBounds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double[]>(
                name: "heart_rate_max_zone_bounds",
                schema: "accounts",
                table: "users",
                type: "double precision[]",
                nullable: true);

            migrationBuilder.AddColumn<double[]>(
                name: "heart_rate_threshold_zone_bounds",
                schema: "accounts",
                table: "users",
                type: "double precision[]",
                nullable: true);

            migrationBuilder.AddColumn<double[]>(
                name: "power_zone_bounds",
                schema: "accounts",
                table: "users",
                type: "double precision[]",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_heart_rate_max_zone_bounds",
                schema: "accounts",
                table: "users",
                sql: "heart_rate_max_zone_bounds IS NULL OR cardinality(heart_rate_max_zone_bounds) = 4");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_heart_rate_threshold_zone_bounds",
                schema: "accounts",
                table: "users",
                sql: "heart_rate_threshold_zone_bounds IS NULL OR cardinality(heart_rate_threshold_zone_bounds) = 4");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_power_zone_bounds",
                schema: "accounts",
                table: "users",
                sql: "power_zone_bounds IS NULL OR cardinality(power_zone_bounds) = 6");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_users_heart_rate_max_zone_bounds",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_heart_rate_threshold_zone_bounds",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_power_zone_bounds",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "heart_rate_max_zone_bounds",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "heart_rate_threshold_zone_bounds",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "power_zone_bounds",
                schema: "accounts",
                table: "users");
        }
    }
}
