using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddUnits : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "units",
                schema: "accounts",
                table: "users",
                type: "character varying(8)",
                maxLength: 8,
                nullable: false,
                defaultValue: "metric");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_units",
                schema: "accounts",
                table: "users",
                sql: "units IN ('metric', 'imperial')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_users_units",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "units",
                schema: "accounts",
                table: "users");
        }
    }
}
