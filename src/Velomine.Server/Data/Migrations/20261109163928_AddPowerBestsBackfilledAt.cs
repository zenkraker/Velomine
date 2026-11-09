using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPowerBestsBackfilledAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "power_bests_backfilled_at",
                schema: "rides",
                table: "rides",
                type: "timestamp with time zone",
                nullable: true);

            // Rides that already have bests, and rides with no power stream, have nothing to backfill. Marking them
            // keeps the backfill from reading the whole history and from reselecting zero-power rides forever.
            migrationBuilder.Sql("""
                UPDATE rides.rides AS r
                SET power_bests_backfilled_at = now()
                WHERE r.status = 'Ready'
                  AND r.power_bests_backfilled_at IS NULL
                  AND (
                    EXISTS (SELECT 1 FROM rides.ride_power_bests AS b WHERE b.ride_id = r.id)
                    OR NOT EXISTS (SELECT 1 FROM rides.ride_streams AS s WHERE s.ride_id = r.id AND s.power IS NOT NULL)
                  );
                """);

            migrationBuilder.CreateIndex(
                name: "ix_view_log_at",
                schema: "sharing",
                table: "view_log",
                column: "at");

            migrationBuilder.CreateIndex(
                name: "ix_rides_power_bests_backfill",
                schema: "rides",
                table: "rides",
                column: "id",
                filter: "status = 'Ready' AND power_bests_backfilled_at IS NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_view_log_at",
                schema: "sharing",
                table: "view_log");

            migrationBuilder.DropIndex(
                name: "ix_rides_power_bests_backfill",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "power_bests_backfilled_at",
                schema: "rides",
                table: "rides");
        }
    }
}
