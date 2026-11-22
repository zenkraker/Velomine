using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class CheckInSleep : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "sleep",
                schema: "wellbeing",
                table: "daily_check_ins",
                type: "integer",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_daily_check_ins_sleep",
                schema: "wellbeing",
                table: "daily_check_ins",
                sql: "sleep IS NULL OR sleep BETWEEN 1 AND 5");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_check_ins_sleep",
                schema: "wellbeing",
                table: "daily_check_ins");

            migrationBuilder.DropColumn(
                name: "sleep",
                schema: "wellbeing",
                table: "daily_check_ins");
        }
    }
}
