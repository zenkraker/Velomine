using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddFtpSuggestions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ftp_suggestions",
                schema: "analytics",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    watts = table.Column<int>(type: "integer", nullable: false),
                    method = table.Column<string>(type: "text", nullable: false),
                    effort_watts = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ftp_suggestions", x => x.id);
                    table.CheckConstraint("ck_ftp_suggestions_effort_watts", "effort_watts BETWEEN 30 AND 1000");
                    table.CheckConstraint("ck_ftp_suggestions_method", "method IN ('20min', '30min', '60min')");
                    table.CheckConstraint("ck_ftp_suggestions_status", "status IN ('open', 'accepted', 'dismissed', 'replaced')");
                    table.CheckConstraint("ck_ftp_suggestions_watts", "watts BETWEEN 30 AND 1000");
                    table.ForeignKey(
                        name: "fk_ftp_suggestions_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_ftp_suggestions_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_ftp_suggestions_user_id",
                schema: "analytics",
                table: "ftp_suggestions",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_ftp_suggestions_ride_id",
                schema: "analytics",
                table: "ftp_suggestions",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ux_ftp_suggestions_open_user",
                schema: "analytics",
                table: "ftp_suggestions",
                column: "user_id",
                unique: true,
                filter: "status = 'open'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ftp_suggestions",
                schema: "analytics");
        }
    }
}
