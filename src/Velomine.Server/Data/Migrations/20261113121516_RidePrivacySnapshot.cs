using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class RidePrivacySnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "hide_cadence",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "hide_elevation",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "hide_heart_rate",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "hide_power",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "hide_speed",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "hide_temperature",
                schema: "rides",
                table: "rides",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "trim_end_m",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "trim_start_m",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_rides_privacy_trim",
                schema: "rides",
                table: "rides",
                sql: "trim_start_m BETWEEN 0 AND 5000 AND trim_end_m BETWEEN 0 AND 5000");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_rides_privacy_trim",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "hide_cadence",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "hide_elevation",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "hide_heart_rate",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "hide_power",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "hide_speed",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "hide_temperature",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "trim_end_m",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "trim_start_m",
                schema: "rides",
                table: "rides");
        }
    }
}
