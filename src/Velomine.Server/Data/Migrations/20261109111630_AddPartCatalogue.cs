using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPartCatalogue : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "build_spec",
                schema: "bikes",
                table: "bikes",
                type: "character varying(60)",
                maxLength: 60,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "frame_size",
                schema: "bikes",
                table: "bikes",
                type: "character varying(24)",
                maxLength: 24,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "model_year",
                schema: "bikes",
                table: "bikes",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "gtin",
                schema: "bikes",
                table: "bike_components",
                type: "character varying(14)",
                maxLength: 14,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "mpn",
                schema: "bikes",
                table: "bike_components",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "part_id",
                schema: "bikes",
                table: "bike_components",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "parts",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    key = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    type = table.Column<string>(type: "character varying(48)", maxLength: 48, nullable: false),
                    brand = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    mpn = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    gtin = table.Column<string>(type: "character varying(14)", maxLength: 14, nullable: true),
                    source = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    confirmations = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_parts", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "ix_bike_components_part_id",
                schema: "bikes",
                table: "bike_components",
                column: "part_id");

            migrationBuilder.CreateIndex(
                name: "ix_parts_key",
                schema: "bikes",
                table: "parts",
                column: "key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_parts_type_brand",
                schema: "bikes",
                table: "parts",
                columns: new[] { "type", "brand" });

            migrationBuilder.AddForeignKey(
                name: "fk_bike_components_parts_part_id",
                schema: "bikes",
                table: "bike_components",
                column: "part_id",
                principalSchema: "bikes",
                principalTable: "parts",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_bike_components_parts_part_id",
                schema: "bikes",
                table: "bike_components");

            migrationBuilder.DropTable(
                name: "parts",
                schema: "bikes");

            migrationBuilder.DropIndex(
                name: "ix_bike_components_part_id",
                schema: "bikes",
                table: "bike_components");

            migrationBuilder.DropColumn(
                name: "build_spec",
                schema: "bikes",
                table: "bikes");

            migrationBuilder.DropColumn(
                name: "frame_size",
                schema: "bikes",
                table: "bikes");

            migrationBuilder.DropColumn(
                name: "model_year",
                schema: "bikes",
                table: "bikes");

            migrationBuilder.DropColumn(
                name: "gtin",
                schema: "bikes",
                table: "bike_components");

            migrationBuilder.DropColumn(
                name: "mpn",
                schema: "bikes",
                table: "bike_components");

            migrationBuilder.DropColumn(
                name: "part_id",
                schema: "bikes",
                table: "bike_components");
        }
    }
}
