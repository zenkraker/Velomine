using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddMaintenanceAndServiceLog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "maintenance_reminders",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    bike_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    interval_distance_m = table.Column<double>(type: "double precision", nullable: true),
                    interval_hours = table.Column<double>(type: "double precision", nullable: true),
                    interval_months = table.Column<int>(type: "integer", nullable: true),
                    last_done_on = table.Column<DateOnly>(type: "date", nullable: false),
                    is_paused = table.Column<bool>(type: "boolean", nullable: false),
                    notified_status = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_maintenance_reminders", x => x.id);
                    table.CheckConstraint("ck_maintenance_reminders_has_interval", "interval_distance_m IS NOT NULL OR interval_hours IS NOT NULL OR interval_months IS NOT NULL");
                    table.CheckConstraint("ck_maintenance_reminders_positive_intervals", "(interval_distance_m IS NULL OR interval_distance_m > 0) AND (interval_hours IS NULL OR interval_hours > 0) AND (interval_months IS NULL OR interval_months > 0)");
                    table.ForeignKey(
                        name: "fk_maintenance_reminders_bikes_bike_id",
                        column: x => x.bike_id,
                        principalSchema: "bikes",
                        principalTable: "bikes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "service_entries",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    bike_id = table.Column<Guid>(type: "uuid", nullable: false),
                    date = table.Column<DateOnly>(type: "date", nullable: false),
                    title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    place = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    cost_amount = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: true),
                    cost_currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: true),
                    component_id = table.Column<Guid>(type: "uuid", nullable: true),
                    reminder_id = table.Column<Guid>(type: "uuid", nullable: true),
                    origin = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_service_entries", x => x.id);
                    table.CheckConstraint("ck_service_entries_cost", "(cost_amount IS NULL) = (cost_currency IS NULL) AND (cost_amount IS NULL OR cost_amount >= 0)");
                    table.ForeignKey(
                        name: "fk_service_entries_bike_components_component_id",
                        column: x => x.component_id,
                        principalSchema: "bikes",
                        principalTable: "bike_components",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_service_entries_bikes_bike_id",
                        column: x => x.bike_id,
                        principalSchema: "bikes",
                        principalTable: "bikes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_service_entries_maintenance_reminders_reminder_id",
                        column: x => x.reminder_id,
                        principalSchema: "bikes",
                        principalTable: "maintenance_reminders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "ix_maintenance_reminders_bike_id",
                schema: "bikes",
                table: "maintenance_reminders",
                column: "bike_id");

            migrationBuilder.CreateIndex(
                name: "ix_service_entries_bike_id_date_id",
                schema: "bikes",
                table: "service_entries",
                columns: new[] { "bike_id", "date", "id" });

            migrationBuilder.CreateIndex(
                name: "ix_service_entries_component_id",
                schema: "bikes",
                table: "service_entries",
                column: "component_id");

            migrationBuilder.CreateIndex(
                name: "ix_service_entries_reminder_id",
                schema: "bikes",
                table: "service_entries",
                column: "reminder_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "service_entries",
                schema: "bikes");

            migrationBuilder.DropTable(
                name: "maintenance_reminders",
                schema: "bikes");
        }
    }
}
