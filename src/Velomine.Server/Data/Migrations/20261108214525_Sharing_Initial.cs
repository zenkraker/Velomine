using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Sharing_Initial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "sharing");

            migrationBuilder.CreateTable(
                name: "grants",
                schema: "sharing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    member_id = table.Column<Guid>(type: "uuid", nullable: false),
                    club_id = table.Column<Guid>(type: "uuid", nullable: false),
                    data_type = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    audience = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_grants", x => x.id);
                    table.CheckConstraint("ck_share_grants_audience", "audience IN ('coaches', 'club')");
                    table.CheckConstraint("ck_share_grants_data_type", "data_type IN ('rides', 'analytics', 'routes')");
                    table.ForeignKey(
                        name: "fk_grants_users_member_id",
                        column: x => x.member_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "view_log",
                schema: "sharing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    member_id = table.Column<Guid>(type: "uuid", nullable: false),
                    club_id = table.Column<Guid>(type: "uuid", nullable: false),
                    viewer_id = table.Column<Guid>(type: "uuid", nullable: false),
                    viewer_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    what = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_view_log", x => x.id);
                    table.ForeignKey(
                        name: "fk_view_log_users_member_id",
                        column: x => x.member_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_grants_club_id",
                schema: "sharing",
                table: "grants",
                column: "club_id");

            migrationBuilder.CreateIndex(
                name: "ix_grants_member_id_data_type",
                schema: "sharing",
                table: "grants",
                columns: new[] { "member_id", "data_type" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_view_log_member_id_at",
                schema: "sharing",
                table: "view_log",
                columns: new[] { "member_id", "at" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "grants",
                schema: "sharing");

            migrationBuilder.DropTable(
                name: "view_log",
                schema: "sharing");
        }
    }
}
