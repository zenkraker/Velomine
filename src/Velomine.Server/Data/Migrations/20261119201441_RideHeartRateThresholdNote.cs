using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class RideHeartRateThresholdNote : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "heart_rate_threshold_note",
                schema: "rides",
                table: "rides",
                type: "character varying(32)",
                maxLength: 32,
                nullable: true);

            // A ride read before this column existed kept its one note in heart_rate_note: the threshold's note moves
            // to its own column, and heart_rate_note keeps the maximum first.
            migrationBuilder.Sql("""
                UPDATE rides.rides
                SET heart_rate_threshold_note = heart_rate_note
                WHERE heart_rate_note LIKE 'threshold%';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "heart_rate_threshold_note",
                schema: "rides",
                table: "rides");
        }
    }
}
