using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Privacy : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "privacy");

            migrationBuilder.CreateTable(
                name: "settings",
                schema: "privacy",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    hide_heart_rate = table.Column<bool>(type: "boolean", nullable: false),
                    hide_power = table.Column<bool>(type: "boolean", nullable: false),
                    hide_cadence = table.Column<bool>(type: "boolean", nullable: false),
                    hide_speed = table.Column<bool>(type: "boolean", nullable: false),
                    hide_elevation = table.Column<bool>(type: "boolean", nullable: false),
                    hide_temperature = table.Column<bool>(type: "boolean", nullable: false),
                    trim_start_m = table.Column<int>(type: "integer", nullable: false),
                    trim_end_m = table.Column<int>(type: "integer", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_settings", x => x.user_id);
                    table.CheckConstraint("ck_privacy_settings_trim", "trim_start_m BETWEEN 0 AND 5000 AND trim_end_m BETWEEN 0 AND 5000");
                    table.ForeignKey(
                        name: "fk_settings_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "zones",
                schema: "privacy",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    latitude = table.Column<double>(type: "double precision", nullable: false),
                    longitude = table.Column<double>(type: "double precision", nullable: false),
                    radius_m = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_zones", x => x.id);
                    table.CheckConstraint("ck_privacy_zones_latitude", "latitude BETWEEN -90 AND 90");
                    table.CheckConstraint("ck_privacy_zones_longitude", "longitude BETWEEN -180 AND 180");
                    table.CheckConstraint("ck_privacy_zones_radius", "radius_m BETWEEN 200 AND 1609");
                    table.ForeignKey(
                        name: "fk_zones_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_zones_user_id",
                schema: "privacy",
                table: "zones",
                column: "user_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "settings",
                schema: "privacy");

            migrationBuilder.DropTable(
                name: "zones",
                schema: "privacy");
        }
    }
}
