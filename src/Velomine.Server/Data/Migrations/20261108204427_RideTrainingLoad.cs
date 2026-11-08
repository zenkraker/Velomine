using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class RideTrainingLoad : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "intensity_factor",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "trimp",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "tss",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "intensity_factor",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "trimp",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "tss",
                schema: "rides",
                table: "rides");
        }
    }
}
