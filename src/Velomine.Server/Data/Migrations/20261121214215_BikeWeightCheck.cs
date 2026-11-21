using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class BikeWeightCheck : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddCheckConstraint(
                name: "ck_bikes_weight_kg",
                schema: "bikes",
                table: "bikes",
                sql: "weight_kg IS NULL OR weight_kg BETWEEN 3 AND 40");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_bikes_weight_kg",
                schema: "bikes",
                table: "bikes");
        }
    }
}
