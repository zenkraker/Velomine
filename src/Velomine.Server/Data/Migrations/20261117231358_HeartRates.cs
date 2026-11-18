using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class HeartRates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "max_heart_rate_bpm",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "threshold_heart_rate_bpm",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "heart_rate_history",
                schema: "accounts",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    kind = table.Column<string>(type: "text", nullable: false),
                    bpm = table.Column<int>(type: "integer", nullable: false),
                    set_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    source = table.Column<string>(type: "text", nullable: false),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_heart_rate_history", x => x.id);
                    table.CheckConstraint("ck_heart_rate_history_bpm", "bpm BETWEEN 80 AND 230");
                    table.CheckConstraint("ck_heart_rate_history_kind", "kind IN ('max', 'threshold')");
                    table.CheckConstraint("ck_heart_rate_history_ride", "ride_id IS NULL OR source = 'measured'");
                    table.CheckConstraint("ck_heart_rate_history_source", "source IN ('manual', 'measured', 'cleared')");
                    table.ForeignKey(
                        name: "fk_heart_rate_history_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_heart_rate_history_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_max_heart_rate_bpm",
                schema: "accounts",
                table: "users",
                sql: "max_heart_rate_bpm BETWEEN 120 AND 230");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_threshold_heart_rate_bpm",
                schema: "accounts",
                table: "users",
                sql: "threshold_heart_rate_bpm BETWEEN 90 AND 220");

            migrationBuilder.CreateIndex(
                name: "ix_heart_rate_history_ride_id",
                schema: "accounts",
                table: "heart_rate_history",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_heart_rate_history_user_id_kind_set_at",
                schema: "accounts",
                table: "heart_rate_history",
                columns: new[] { "user_id", "kind", "set_at" },
                descending: new[] { false, false, true });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "heart_rate_history",
                schema: "accounts");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_max_heart_rate_bpm",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_threshold_heart_rate_bpm",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "max_heart_rate_bpm",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "threshold_heart_rate_bpm",
                schema: "accounts",
                table: "users");
        }
    }
}
