using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddClubRides : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "calendar");

            migrationBuilder.AddColumn<Guid>(
                name: "planned_ride_id",
                schema: "notifications",
                table: "notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "calendar_feeds",
                schema: "calendar",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    club_id = table.Column<Guid>(type: "uuid", nullable: false),
                    token_hash = table.Column<byte[]>(type: "bytea", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_calendar_feeds", x => x.user_id);
                    table.ForeignKey(
                        name: "fk_calendar_feeds_clubs_club_id",
                        column: x => x.club_id,
                        principalSchema: "clubs",
                        principalTable: "clubs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_calendar_feeds_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "planned_rides",
                schema: "calendar",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    club_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_by_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    title = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    starts_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    utc_offset_minutes = table.Column<int>(type: "integer", nullable: false),
                    meeting_name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    meeting_latitude = table.Column<double>(type: "double precision", nullable: false),
                    meeting_longitude = table.Column<double>(type: "double precision", nullable: false),
                    route_id = table.Column<Guid>(type: "uuid", nullable: true),
                    pace = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    no_drop = table.Column<bool>(type: "boolean", nullable: false),
                    notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    max_riders = table.Column<int>(type: "integer", nullable: true),
                    cancelled_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_planned_rides", x => x.id);
                    table.CheckConstraint("ck_planned_rides_latitude", "meeting_latitude BETWEEN -90 AND 90");
                    table.CheckConstraint("ck_planned_rides_longitude", "meeting_longitude BETWEEN -180 AND 180");
                    table.CheckConstraint("ck_planned_rides_max_riders", "max_riders IS NULL OR max_riders > 0");
                    table.CheckConstraint("ck_planned_rides_meeting", "char_length(btrim(meeting_name)) > 0");
                    table.CheckConstraint("ck_planned_rides_offset", "utc_offset_minutes BETWEEN -840 AND 840");
                    table.CheckConstraint("ck_planned_rides_pace", "pace IN ('easy', 'steady', 'fast')");
                    table.CheckConstraint("ck_planned_rides_title", "char_length(btrim(title)) > 0");
                    table.ForeignKey(
                        name: "fk_planned_rides_clubs_club_id",
                        column: x => x.club_id,
                        principalSchema: "clubs",
                        principalTable: "clubs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_planned_rides_routes_route_id",
                        column: x => x.route_id,
                        principalSchema: "routes",
                        principalTable: "routes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_planned_rides_users_created_by_user_id",
                        column: x => x.created_by_user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ride_sign_ups",
                schema: "calendar",
                columns: table => new
                {
                    planned_ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ride_sign_ups", x => new { x.planned_ride_id, x.user_id });
                    table.ForeignKey(
                        name: "fk_ride_sign_ups_planned_rides_planned_ride_id",
                        column: x => x.planned_ride_id,
                        principalSchema: "calendar",
                        principalTable: "planned_rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_ride_sign_ups_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_notifications_planned_ride_id",
                schema: "notifications",
                table: "notifications",
                column: "planned_ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_calendar_feeds_club_id",
                schema: "calendar",
                table: "calendar_feeds",
                column: "club_id");

            migrationBuilder.CreateIndex(
                name: "ix_calendar_feeds_token_hash",
                schema: "calendar",
                table: "calendar_feeds",
                column: "token_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_planned_rides_club_id_starts_at",
                schema: "calendar",
                table: "planned_rides",
                columns: new[] { "club_id", "starts_at" });

            migrationBuilder.CreateIndex(
                name: "ix_planned_rides_created_by_user_id",
                schema: "calendar",
                table: "planned_rides",
                column: "created_by_user_id");

            migrationBuilder.CreateIndex(
                name: "ix_planned_rides_route_id",
                schema: "calendar",
                table: "planned_rides",
                column: "route_id");

            migrationBuilder.CreateIndex(
                name: "ix_ride_sign_ups_user_id",
                schema: "calendar",
                table: "ride_sign_ups",
                column: "user_id");

            migrationBuilder.AddForeignKey(
                name: "fk_notifications_planned_rides_planned_ride_id",
                schema: "notifications",
                table: "notifications",
                column: "planned_ride_id",
                principalSchema: "calendar",
                principalTable: "planned_rides",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_notifications_planned_rides_planned_ride_id",
                schema: "notifications",
                table: "notifications");

            migrationBuilder.DropTable(
                name: "calendar_feeds",
                schema: "calendar");

            migrationBuilder.DropTable(
                name: "ride_sign_ups",
                schema: "calendar");

            migrationBuilder.DropTable(
                name: "planned_rides",
                schema: "calendar");

            migrationBuilder.DropIndex(
                name: "ix_notifications_planned_ride_id",
                schema: "notifications",
                table: "notifications");

            migrationBuilder.DropColumn(
                name: "planned_ride_id",
                schema: "notifications",
                table: "notifications");
        }
    }
}
