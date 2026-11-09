using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRideDimensions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "assist",
                schema: "rides",
                table: "rides",
                type: "character varying(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "commute",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "discipline",
                schema: "rides",
                table: "rides",
                type: "character varying(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "environment",
                schema: "rides",
                table: "rides",
                type: "character varying(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_rides_user_id_discipline",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "discipline" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_rides_user_id_discipline",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "assist",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "commute",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "discipline",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "environment",
                schema: "rides",
                table: "rides");
        }
    }
}
