using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRideLaps : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ride_laps",
                schema: "rides",
                columns: table => new
                {
                    ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    index = table.Column<int>(type: "integer", nullable: false),
                    start_s = table.Column<double>(type: "double precision", nullable: false),
                    end_s = table.Column<double>(type: "double precision", nullable: false),
                    duration_s = table.Column<double>(type: "double precision", nullable: false),
                    moving_s = table.Column<double>(type: "double precision", nullable: false),
                    distance_m = table.Column<double>(type: "double precision", nullable: false),
                    avg_speed_ms = table.Column<double>(type: "double precision", nullable: true),
                    max_speed_ms = table.Column<double>(type: "double precision", nullable: true),
                    avg_power_w = table.Column<int>(type: "integer", nullable: true),
                    max_power_w = table.Column<int>(type: "integer", nullable: true),
                    avg_heart_rate = table.Column<int>(type: "integer", nullable: true),
                    max_heart_rate = table.Column<int>(type: "integer", nullable: true),
                    avg_cadence = table.Column<int>(type: "integer", nullable: true),
                    elevation_gain_m = table.Column<double>(type: "double precision", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ride_laps", x => new { x.ride_id, x.index });
                    table.ForeignKey(
                        name: "fk_ride_laps_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ride_laps",
                schema: "rides");
        }
    }
}
