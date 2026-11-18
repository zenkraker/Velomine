using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class HeartRateHistorySequence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_heart_rate_history_user_id_kind_set_at",
                schema: "accounts",
                table: "heart_rate_history");

            migrationBuilder.AddColumn<int>(
                name: "sequence",
                schema: "accounts",
                table: "heart_rate_history",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "ix_heart_rate_history_user_id_kind_set_at_sequence",
                schema: "accounts",
                table: "heart_rate_history",
                columns: new[] { "user_id", "kind", "set_at", "sequence" },
                descending: new[] { false, false, true, true });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_heart_rate_history_user_id_kind_set_at_sequence",
                schema: "accounts",
                table: "heart_rate_history");

            migrationBuilder.DropColumn(
                name: "sequence",
                schema: "accounts",
                table: "heart_rate_history");

            migrationBuilder.CreateIndex(
                name: "ix_heart_rate_history_user_id_kind_set_at",
                schema: "accounts",
                table: "heart_rate_history",
                columns: new[] { "user_id", "kind", "set_at" },
                descending: new[] { false, false, true });
        }
    }
}
