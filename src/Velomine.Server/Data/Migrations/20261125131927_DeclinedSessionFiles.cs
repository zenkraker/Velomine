using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class DeclinedSessionFiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string[]>(
                name: "declined_file_hashes",
                schema: "training",
                table: "plans",
                type: "text[]",
                nullable: false,
                defaultValue: new string[0]);

            migrationBuilder.AddCheckConstraint(
                name: "ck_training_plans_declined_files",
                schema: "training",
                table: "plans",
                sql: "cardinality(declined_file_hashes) <= 20");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_training_plans_declined_files",
                schema: "training",
                table: "plans");

            migrationBuilder.DropColumn(
                name: "declined_file_hashes",
                schema: "training",
                table: "plans");
        }
    }
}
