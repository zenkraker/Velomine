using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class RideTitleDescription : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ride_id",
                schema: "sharing",
                table: "view_log",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "description",
                schema: "rides",
                table: "rides",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "title",
                schema: "rides",
                table: "rides",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_view_log_ride_id_at",
                schema: "sharing",
                table: "view_log",
                columns: new[] { "ride_id", "at" },
                filter: "ride_id IS NOT NULL");

            migrationBuilder.AddCheckConstraint(
                name: "ck_rides_description_length",
                schema: "rides",
                table: "rides",
                sql: "char_length(description) BETWEEN 1 AND 2000");

            migrationBuilder.AddCheckConstraint(
                name: "ck_rides_title_length",
                schema: "rides",
                table: "rides",
                sql: "char_length(title) BETWEEN 1 AND 120");

            migrationBuilder.AddForeignKey(
                name: "fk_view_log_rides_ride_id",
                schema: "sharing",
                table: "view_log",
                column: "ride_id",
                principalSchema: "rides",
                principalTable: "rides",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_view_log_rides_ride_id",
                schema: "sharing",
                table: "view_log");

            migrationBuilder.DropIndex(
                name: "ix_view_log_ride_id_at",
                schema: "sharing",
                table: "view_log");

            migrationBuilder.DropCheckConstraint(
                name: "ck_rides_description_length",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropCheckConstraint(
                name: "ck_rides_title_length",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "ride_id",
                schema: "sharing",
                table: "view_log");

            migrationBuilder.DropColumn(
                name: "description",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "title",
                schema: "rides",
                table: "rides");
        }
    }
}
