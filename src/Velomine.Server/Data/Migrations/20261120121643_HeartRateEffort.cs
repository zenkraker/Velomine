using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class HeartRateEffort : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "hr_tss",
                schema: "rides",
                table: "rides",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "load_threshold_heart_rate",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "hr_tss",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "load_threshold_heart_rate",
                schema: "rides",
                table: "rides");
        }
    }
}
