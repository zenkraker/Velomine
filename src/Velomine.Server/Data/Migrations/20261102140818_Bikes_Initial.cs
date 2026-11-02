using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Bikes_Initial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "bikes");

            migrationBuilder.AddColumn<Guid>(
                name: "bike_id",
                schema: "rides",
                table: "rides",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "bikes",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    brand = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    kind = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    wheel_circumference_mm = table.Column<int>(type: "integer", nullable: false),
                    initial_distance_m = table.Column<double>(type: "double precision", nullable: false),
                    purchased_on = table.Column<DateOnly>(type: "date", nullable: true),
                    is_default = table.Column<bool>(type: "boolean", nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_bikes", x => x.id);
                    table.ForeignKey(
                        name: "fk_bikes_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "bike_components",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    bike_id = table.Column<Guid>(type: "uuid", nullable: false),
                    type = table.Column<string>(type: "character varying(48)", maxLength: 48, nullable: false),
                    brand = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    installed_on = table.Column<DateOnly>(type: "date", nullable: false),
                    removed_on = table.Column<DateOnly>(type: "date", nullable: true),
                    expected_distance_m = table.Column<double>(type: "double precision", nullable: true),
                    expected_hours = table.Column<double>(type: "double precision", nullable: true),
                    expected_months = table.Column<int>(type: "integer", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_bike_components", x => x.id);
                    table.ForeignKey(
                        name: "fk_bike_components_bikes_bike_id",
                        column: x => x.bike_id,
                        principalSchema: "bikes",
                        principalTable: "bikes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_rides_bike_id",
                schema: "rides",
                table: "rides",
                column: "bike_id");

            migrationBuilder.CreateIndex(
                name: "ix_bike_components_bike_id",
                schema: "bikes",
                table: "bike_components",
                column: "bike_id");

            migrationBuilder.CreateIndex(
                name: "ux_bikes_one_default_per_user",
                schema: "bikes",
                table: "bikes",
                column: "user_id",
                unique: true,
                filter: "is_default");

            migrationBuilder.AddForeignKey(
                name: "fk_rides_bikes_bike_id",
                schema: "rides",
                table: "rides",
                column: "bike_id",
                principalSchema: "bikes",
                principalTable: "bikes",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_rides_bikes_bike_id",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropTable(
                name: "bike_components",
                schema: "bikes");

            migrationBuilder.DropTable(
                name: "bikes",
                schema: "bikes");

            migrationBuilder.DropIndex(
                name: "ix_rides_bike_id",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "bike_id",
                schema: "rides",
                table: "rides");
        }
    }
}
