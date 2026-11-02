using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Rides_Initial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "rides");

            migrationBuilder.CreateTable(
                name: "rides",
                schema: "rides",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    error = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    duplicate_of = table.Column<Guid>(type: "uuid", nullable: true),
                    idempotency_key = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    file_sha256 = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    file_name = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    dedup_key = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    uploaded_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    start_time = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    utc_offset_minutes = table.Column<int>(type: "integer", nullable: true),
                    device = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    distance_m = table.Column<double>(type: "double precision", nullable: true),
                    elapsed_s = table.Column<double>(type: "double precision", nullable: true),
                    moving_s = table.Column<double>(type: "double precision", nullable: true),
                    elevation_gain_m = table.Column<double>(type: "double precision", nullable: true),
                    elevation_loss_m = table.Column<double>(type: "double precision", nullable: true),
                    avg_speed_ms = table.Column<double>(type: "double precision", nullable: true),
                    max_speed_ms = table.Column<double>(type: "double precision", nullable: true),
                    speed_source = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: true),
                    avg_power_w = table.Column<int>(type: "integer", nullable: true),
                    max_power_w = table.Column<int>(type: "integer", nullable: true),
                    normalized_power_w = table.Column<int>(type: "integer", nullable: true),
                    avg_heart_rate = table.Column<int>(type: "integer", nullable: true),
                    max_heart_rate = table.Column<int>(type: "integer", nullable: true),
                    avg_cadence = table.Column<int>(type: "integer", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_rides", x => x.id);
                    table.ForeignKey(
                        name: "fk_rides_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ride_streams",
                schema: "rides",
                columns: table => new
                {
                    ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    time = table.Column<double[]>(type: "double precision[]", nullable: false),
                    latitude = table.Column<double?[]>(type: "double precision[]", nullable: true),
                    longitude = table.Column<double?[]>(type: "double precision[]", nullable: true),
                    altitude = table.Column<float?[]>(type: "real[]", nullable: true),
                    speed = table.Column<float?[]>(type: "real[]", nullable: true),
                    distance = table.Column<float?[]>(type: "real[]", nullable: true),
                    heart_rate = table.Column<short?[]>(type: "smallint[]", nullable: true),
                    power = table.Column<short?[]>(type: "smallint[]", nullable: true),
                    cadence = table.Column<short?[]>(type: "smallint[]", nullable: true),
                    temperature = table.Column<short?[]>(type: "smallint[]", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ride_streams", x => x.ride_id);
                    table.ForeignKey(
                        name: "fk_ride_streams_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_rides_user_id_dedup_key",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "dedup_key" });

            migrationBuilder.CreateIndex(
                name: "ix_rides_user_id_idempotency_key",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "idempotency_key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_rides_user_id_start_time",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "start_time" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ride_streams",
                schema: "rides");

            migrationBuilder.DropTable(
                name: "rides",
                schema: "rides");
        }
    }
}
