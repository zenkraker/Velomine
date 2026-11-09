using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddClubLocation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "is_discoverable",
                schema: "clubs",
                table: "clubs",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<double>(
                name: "latitude",
                schema: "clubs",
                table: "clubs",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "longitude",
                schema: "clubs",
                table: "clubs",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_clubs_latitude",
                schema: "clubs",
                table: "clubs",
                sql: "latitude IS NULL OR (latitude BETWEEN -90 AND 90)");

            migrationBuilder.AddCheckConstraint(
                name: "ck_clubs_location",
                schema: "clubs",
                table: "clubs",
                sql: "(latitude IS NULL) = (longitude IS NULL)");

            migrationBuilder.AddCheckConstraint(
                name: "ck_clubs_longitude",
                schema: "clubs",
                table: "clubs",
                sql: "longitude IS NULL OR (longitude BETWEEN -180 AND 180)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_clubs_latitude",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_clubs_location",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_clubs_longitude",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropColumn(
                name: "is_discoverable",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropColumn(
                name: "latitude",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropColumn(
                name: "longitude",
                schema: "clubs",
                table: "clubs");
        }
    }
}
