using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCatalogueContributionsAndTemplates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "bike_templates",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_bike_templates", x => x.id);
                    table.ForeignKey(
                        name: "fk_bike_templates_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "catalogue_conflicts",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    key = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    type = table.Column<string>(type: "character varying(48)", maxLength: 48, nullable: false),
                    local_brand = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    local_model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    local_mpn = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    local_gtin = table.Column<string>(type: "character varying(14)", maxLength: 14, nullable: true),
                    shared_brand = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    shared_model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    shared_mpn = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    shared_gtin = table.Column<string>(type: "character varying(14)", maxLength: 14, nullable: true),
                    incoming_hash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    resolved_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_catalogue_conflicts", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "catalogue_settings",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false),
                    contributions_enabled = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_catalogue_settings", x => x.id);
                    table.CheckConstraint("ck_catalogue_settings_one_row", "id = 1");
                });

            migrationBuilder.CreateTable(
                name: "part_contributions",
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
                    payload_hash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    attempts = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    next_attempt_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    sent_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_part_contributions", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "bike_template_parts",
                schema: "bikes",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    template_id = table.Column<Guid>(type: "uuid", nullable: false),
                    type = table.Column<string>(type: "character varying(48)", maxLength: 48, nullable: false),
                    brand = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    mpn = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    gtin = table.Column<string>(type: "character varying(14)", maxLength: 14, nullable: true),
                    expected_distance_m = table.Column<double>(type: "double precision", nullable: true),
                    expected_hours = table.Column<double>(type: "double precision", nullable: true),
                    expected_months = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_bike_template_parts", x => x.id);
                    table.ForeignKey(
                        name: "fk_bike_template_parts_bike_templates_template_id",
                        column: x => x.template_id,
                        principalSchema: "bikes",
                        principalTable: "bike_templates",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_bike_template_parts_template_id",
                schema: "bikes",
                table: "bike_template_parts",
                column: "template_id");

            migrationBuilder.CreateIndex(
                name: "ix_bike_templates_user_id",
                schema: "bikes",
                table: "bike_templates",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ux_catalogue_conflicts_one_pending_per_key",
                schema: "bikes",
                table: "catalogue_conflicts",
                column: "key",
                unique: true,
                filter: "status = 'pending'");

            migrationBuilder.CreateIndex(
                name: "ix_part_contributions_key_payload_hash",
                schema: "bikes",
                table: "part_contributions",
                columns: new[] { "key", "payload_hash" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_part_contributions_status_next_attempt_at",
                schema: "bikes",
                table: "part_contributions",
                columns: new[] { "status", "next_attempt_at" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "bike_template_parts",
                schema: "bikes");

            migrationBuilder.DropTable(
                name: "catalogue_conflicts",
                schema: "bikes");

            migrationBuilder.DropTable(
                name: "catalogue_settings",
                schema: "bikes");

            migrationBuilder.DropTable(
                name: "part_contributions",
                schema: "bikes");

            migrationBuilder.DropTable(
                name: "bike_templates",
                schema: "bikes");
        }
    }
}
