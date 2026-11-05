using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Admin_Settings_Email : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "admin");

            migrationBuilder.AddColumn<bool>(
                name: "email_notifications",
                schema: "accounts",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "emailed_at",
                schema: "notifications",
                table: "notifications",
                type: "timestamp with time zone",
                nullable: true);

            // Notifications that exist before email is switched on are never emailed.
            migrationBuilder.Sql("UPDATE notifications.notifications SET emailed_at = now() WHERE emailed_at IS NULL;");

            migrationBuilder.CreateTable(
                name: "server_settings",
                schema: "admin",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false),
                    sign_up_enabled = table.Column<bool>(type: "boolean", nullable: true),
                    require_admin_approval = table.Column<bool>(type: "boolean", nullable: true),
                    map_tile_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    map_attribution = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    email_started_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_server_settings", x => x.id);
                    table.CheckConstraint("ck_server_settings_one_row", "id = 1");
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "server_settings",
                schema: "admin");

            migrationBuilder.DropColumn(
                name: "email_notifications",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "emailed_at",
                schema: "notifications",
                table: "notifications");
        }
    }
}
