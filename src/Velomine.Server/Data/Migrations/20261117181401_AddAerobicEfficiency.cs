using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAerobicEfficiency : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "decoupling_pct",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "efficiency_factor",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "steady",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "decoupling_pct",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "efficiency_factor",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "steady",
                schema: "rides",
                table: "rides");
        }
    }
}
