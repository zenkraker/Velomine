using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class EstimatedPower : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "estimated_avg_power_w",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "estimated_normalized_power_w",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "estimated_tss",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<short?[]>(
                name: "estimated_power",
                schema: "rides",
                table: "ride_streams",
                type: "smallint[]",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "weight_kg",
                schema: "bikes",
                table: "bikes",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "estimated_avg_power_w",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "estimated_normalized_power_w",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "estimated_tss",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "estimated_power",
                schema: "rides",
                table: "ride_streams");

            migrationBuilder.DropColumn(
                name: "weight_kg",
                schema: "bikes",
                table: "bikes");
        }
    }
}
