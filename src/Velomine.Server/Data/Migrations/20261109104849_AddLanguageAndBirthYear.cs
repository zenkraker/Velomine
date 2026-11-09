using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddLanguageAndBirthYear : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "birth_year",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "language",
                schema: "accounts",
                table: "users",
                type: "character varying(8)",
                maxLength: 8,
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_birth_year",
                schema: "accounts",
                table: "users",
                sql: "birth_year IS NULL OR birth_year BETWEEN 1900 AND 2200");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_users_birth_year",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "birth_year",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "language",
                schema: "accounts",
                table: "users");
        }
    }
}
