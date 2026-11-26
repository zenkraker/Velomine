using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddFtpHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ftp_history",
                schema: "accounts",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    watts = table.Column<int>(type: "integer", nullable: false),
                    set_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    source = table.Column<string>(type: "text", nullable: false),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ftp_history", x => x.id);
                    table.CheckConstraint("ck_ftp_history_source", "source IN ('manual', 'estimate', 'test', 'earlier')");
                    table.CheckConstraint("ck_ftp_history_watts", "watts BETWEEN 30 AND 1000");
                    table.ForeignKey(
                        name: "fk_ftp_history_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_ftp_history_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_ftp_history_ride_id",
                schema: "accounts",
                table: "ftp_history",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_ftp_history_user_id_set_at_id",
                schema: "accounts",
                table: "ftp_history",
                columns: new[] { "user_id", "set_at", "id" },
                descending: new[] { false, true, true });

            // The FTP each member had before history was kept: one "earlier" row, dated now, with no ride.
            migrationBuilder.Sql("""
                INSERT INTO accounts.ftp_history (id, user_id, watts, set_at, source, ride_id)
                SELECT gen_random_uuid(), id, ftp_w, now(), 'earlier', NULL
                FROM accounts.users
                WHERE ftp_w IS NOT NULL;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ftp_history",
                schema: "accounts");
        }
    }
}
