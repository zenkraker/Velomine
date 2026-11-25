using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class SessionMinutesAndLighterWeeks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "minutes",
                schema: "training",
                table: "sessions",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateOnly[]>(
                name: "lighter_weeks",
                schema: "training",
                table: "plans",
                type: "date[]",
                nullable: false,
                defaultValue: new DateOnly[0]);

            migrationBuilder.AddCheckConstraint(
                name: "ck_training_sessions_minutes",
                schema: "training",
                table: "sessions",
                sql: "minutes BETWEEN 0 AND 1440");

            migrationBuilder.CreateIndex(
                name: "ix_plans_last_planned_for",
                schema: "training",
                table: "plans",
                column: "last_planned_for",
                filter: "is_on");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_training_sessions_minutes",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropIndex(
                name: "ix_plans_last_planned_for",
                schema: "training",
                table: "plans");

            migrationBuilder.DropColumn(
                name: "minutes",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropColumn(
                name: "lighter_weeks",
                schema: "training",
                table: "plans");
        }
    }
}
