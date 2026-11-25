using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class TrainingAdapts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "easy_moved_to",
                schema: "training",
                table: "sessions",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "easy_reason",
                schema: "training",
                table: "sessions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "original_recipe",
                schema: "training",
                table: "sessions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "reminded_for",
                schema: "training",
                table: "plans",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "training_session_id",
                schema: "notifications",
                table: "notifications",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_training_sessions_easy_reason",
                schema: "training",
                table: "sessions",
                sql: "easy_reason IS NULL OR easy_reason IN ('slept_poorly', 'tired', 'sore', 'form_low', 'asked')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_training_sessions_original_recipe",
                schema: "training",
                table: "sessions",
                sql: "original_recipe IS NULL OR length(original_recipe) BETWEEN 2 AND 8");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_training_session_id",
                schema: "notifications",
                table: "notifications",
                column: "training_session_id");

            migrationBuilder.AddForeignKey(
                name: "fk_notifications_sessions_training_session_id",
                schema: "notifications",
                table: "notifications",
                column: "training_session_id",
                principalSchema: "training",
                principalTable: "sessions",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_notifications_sessions_training_session_id",
                schema: "notifications",
                table: "notifications");

            migrationBuilder.DropCheckConstraint(
                name: "ck_training_sessions_easy_reason",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropCheckConstraint(
                name: "ck_training_sessions_original_recipe",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropIndex(
                name: "ix_notifications_training_session_id",
                schema: "notifications",
                table: "notifications");

            migrationBuilder.DropColumn(
                name: "easy_moved_to",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropColumn(
                name: "easy_reason",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropColumn(
                name: "original_recipe",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropColumn(
                name: "reminded_for",
                schema: "training",
                table: "plans");

            migrationBuilder.DropColumn(
                name: "training_session_id",
                schema: "notifications",
                table: "notifications");
        }
    }
}
