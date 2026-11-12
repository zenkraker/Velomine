using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSupporterLicences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "supporter");

            migrationBuilder.CreateTable(
                name: "licences",
                schema: "supporter",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    club_id = table.Column<Guid>(type: "uuid", nullable: true),
                    holder = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    serial = table.Column<int>(type: "integer", nullable: false),
                    activated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    hidden = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_licences", x => x.id);
                    table.CheckConstraint("ck_supporter_licences_holder", "(user_id IS NULL) <> (club_id IS NULL)");
                    table.CheckConstraint("ck_supporter_licences_serial", "serial > 0");
                    table.ForeignKey(
                        name: "fk_licences_clubs_club_id",
                        column: x => x.club_id,
                        principalSchema: "clubs",
                        principalTable: "clubs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_licences_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_licences_club_id",
                schema: "supporter",
                table: "licences",
                column: "club_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_licences_serial",
                schema: "supporter",
                table: "licences",
                column: "serial",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_licences_user_id",
                schema: "supporter",
                table: "licences",
                column: "user_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "licences",
                schema: "supporter");
        }
    }
}
