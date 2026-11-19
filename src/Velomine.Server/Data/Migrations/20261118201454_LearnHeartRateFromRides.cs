using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class LearnHeartRateFromRides : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "heart_rate_note",
                schema: "rides",
                table: "rides",
                type: "character varying(32)",
                maxLength: 32,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "heart_rate_suggestions",
                schema: "analytics",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    kind = table.Column<string>(type: "text", nullable: false),
                    bpm = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_heart_rate_suggestions", x => x.id);
                    table.CheckConstraint("ck_heart_rate_suggestions_bpm", "bpm BETWEEN 80 AND 230");
                    table.CheckConstraint("ck_heart_rate_suggestions_kind", "kind IN ('max', 'threshold')");
                    table.CheckConstraint("ck_heart_rate_suggestions_status", "status IN ('open', 'accepted', 'dismissed', 'replaced')");
                    table.ForeignKey(
                        name: "fk_heart_rate_suggestions_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_heart_rate_suggestions_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_heart_rate_suggestions_ride_id",
                schema: "analytics",
                table: "heart_rate_suggestions",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_heart_rate_suggestions_user_id",
                schema: "analytics",
                table: "heart_rate_suggestions",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ux_heart_rate_suggestions_open_user_kind",
                schema: "analytics",
                table: "heart_rate_suggestions",
                columns: new[] { "user_id", "kind" },
                unique: true,
                filter: "status = 'open'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "heart_rate_suggestions",
                schema: "analytics");

            migrationBuilder.DropColumn(
                name: "heart_rate_note",
                schema: "rides",
                table: "rides");
        }
    }
}
