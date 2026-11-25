using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class SessionQuestion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "question_ride_id",
                schema: "training",
                table: "sessions",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_sessions_question_ride_id",
                schema: "training",
                table: "sessions",
                column: "question_ride_id",
                unique: true,
                filter: "question_ride_id IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "fk_sessions_rides_question_ride_id",
                schema: "training",
                table: "sessions",
                column: "question_ride_id",
                principalSchema: "rides",
                principalTable: "rides",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_sessions_rides_question_ride_id",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropIndex(
                name: "ix_sessions_question_ride_id",
                schema: "training",
                table: "sessions");

            migrationBuilder.DropColumn(
                name: "question_ride_id",
                schema: "training",
                table: "sessions");
        }
    }
}
