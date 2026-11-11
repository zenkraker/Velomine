using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddClubPlans : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "club_creation_enabled",
                schema: "admin",
                table: "server_settings",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "member_limit",
                schema: "clubs",
                table: "clubs",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "paid_until",
                schema: "clubs",
                table: "clubs",
                type: "date",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_clubs_member_limit",
                schema: "clubs",
                table: "clubs",
                sql: "member_limit IS NULL OR member_limit > 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_clubs_member_limit",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropColumn(
                name: "club_creation_enabled",
                schema: "admin",
                table: "server_settings");

            migrationBuilder.DropColumn(
                name: "member_limit",
                schema: "clubs",
                table: "clubs");

            migrationBuilder.DropColumn(
                name: "paid_until",
                schema: "clubs",
                table: "clubs");
        }
    }
}
