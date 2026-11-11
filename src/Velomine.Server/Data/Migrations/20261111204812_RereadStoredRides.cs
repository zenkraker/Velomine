using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class RereadStoredRides : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "load_ftp_w",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "load_max_heart_rate",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "parser_version",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: false,
                defaultValue: 1); // rides already stored count as read with the current parser: nothing happens until it is raised

            migrationBuilder.AddColumn<int>(
                name: "reparse_failed_version",
                schema: "rides",
                table: "rides",
                type: "integer",
                nullable: true);

            // Without a lock on writes to a table that holds every ride.
            migrationBuilder.Sql(
                "CREATE INDEX CONCURRENTLY ix_rides_reparse ON rides.rides (parser_version, uploaded_at, id) WHERE status IN ('Ready','Failed');",
                suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_rides_reparse",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "load_ftp_w",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "load_max_heart_rate",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "parser_version",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "reparse_failed_version",
                schema: "rides",
                table: "rides");
        }
    }
}
