using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTrainingEvents : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "training");

            migrationBuilder.CreateTable(
                name: "events",
                schema: "training",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "text", nullable: false),
                    date = table.Column<DateOnly>(type: "date", nullable: false),
                    kind = table.Column<string>(type: "text", nullable: false),
                    distance_m = table.Column<double>(type: "double precision", nullable: true),
                    elevation_gain_m = table.Column<double>(type: "double precision", nullable: true),
                    notes = table.Column<string>(type: "text", nullable: true),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_events", x => x.id);
                    table.CheckConstraint("ck_events_distance_m", "distance_m IS NULL OR distance_m >= 0");
                    table.CheckConstraint("ck_events_elevation_gain_m", "elevation_gain_m IS NULL OR elevation_gain_m >= 0");
                    table.CheckConstraint("ck_events_kind", "kind IN ('race', 'sportive', 'tour', 'other')");
                    table.CheckConstraint("ck_events_name_length", "length(name) BETWEEN 1 AND 100");
                    table.CheckConstraint("ck_events_notes_length", "notes IS NULL OR length(notes) <= 500");
                    table.ForeignKey(
                        name: "fk_events_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_events_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_events_ride_id",
                schema: "training",
                table: "events",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_events_user_id_date",
                schema: "training",
                table: "events",
                columns: new[] { "user_id", "date" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "events",
                schema: "training");
        }
    }
}
