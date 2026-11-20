using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRiderMode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "rider_mode",
                schema: "accounts",
                table: "users",
                type: "character varying(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_rider_mode",
                schema: "accounts",
                table: "users",
                sql: "rider_mode IS NULL OR rider_mode IN ('just_riding', 'with_goals', 'training')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_users_rider_mode",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "rider_mode",
                schema: "accounts",
                table: "users");
        }
    }
}
