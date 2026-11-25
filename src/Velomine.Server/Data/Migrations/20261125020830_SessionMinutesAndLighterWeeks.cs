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

            // The sessions planned before the column existed read the least length of their own recipe, so the first
            // week after the upgrade budgets and scores what it carries. The least lengths are the recipe table's.
            migrationBuilder.Sql("""
                UPDATE training.sessions SET minutes = CASE recipe
                    WHEN 'R01' THEN 30 WHEN 'R02' THEN 45 WHEN 'R03' THEN 60 WHEN 'R04' THEN 60 WHEN 'R05' THEN 60
                    WHEN 'R06' THEN 50 WHEN 'R07' THEN 70 WHEN 'R08' THEN 55 WHEN 'R09' THEN 50 WHEN 'R10' THEN 45
                    WHEN 'R12' THEN 45 WHEN 'R14' THEN 30 WHEN 'R15' THEN 45 WHEN 'R16' THEN 60 WHEN 'R17' THEN 45
                    ELSE 45 END
                WHERE minutes = 0;
                """);

            migrationBuilder.AddCheckConstraint(
                name: "ck_training_sessions_minutes",
                schema: "training",
                table: "sessions",
                sql: "minutes BETWEEN 1 AND 1440");

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
