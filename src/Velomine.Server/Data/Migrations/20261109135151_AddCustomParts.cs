using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCustomParts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "is_custom",
                schema: "bikes",
                table: "bike_template_parts",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "is_custom",
                schema: "bikes",
                table: "bike_components",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            // A component with no catalogue link was free text, so it becomes custom. Existing template parts were
            // saved before the shared list was publisher-authoritative; keep them custom so they never push legacy data.
            migrationBuilder.Sql("UPDATE bikes.bike_components SET is_custom = (part_id IS NULL);");
            migrationBuilder.Sql("UPDATE bikes.bike_template_parts SET is_custom = TRUE;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "is_custom",
                schema: "bikes",
                table: "bike_template_parts");

            migrationBuilder.DropColumn(
                name: "is_custom",
                schema: "bikes",
                table: "bike_components");
        }
    }
}
