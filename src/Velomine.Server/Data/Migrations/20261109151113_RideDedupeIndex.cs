using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class RideDedupeIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_rides_user_id_dedup_key",
                schema: "rides",
                table: "rides");

            migrationBuilder.CreateIndex(
                name: "ux_rides_user_dedup_key",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "dedup_key" },
                unique: true,
                filter: "status IN ('Processing','Ready')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ux_rides_user_dedup_key",
                schema: "rides",
                table: "rides");

            migrationBuilder.CreateIndex(
                name: "ix_rides_user_id_dedup_key",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "dedup_key" });
        }
    }
}
