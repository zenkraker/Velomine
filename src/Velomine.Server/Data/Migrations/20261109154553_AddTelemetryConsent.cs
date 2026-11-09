using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTelemetryConsent : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "telemetry_consent_at",
                schema: "accounts",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "telemetry_consent_version",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "telemetry_crash",
                schema: "accounts",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "telemetry_usage",
                schema: "accounts",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "telemetry_consent_at",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "telemetry_consent_version",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "telemetry_crash",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "telemetry_usage",
                schema: "accounts",
                table: "users");
        }
    }
}
