using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Clubs_Initial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "clubs");

            migrationBuilder.CreateTable(
                name: "clubs",
                schema: "clubs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    join_code = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_clubs", x => x.id);
                    table.CheckConstraint("ck_clubs_join_code", "char_length(join_code) >= 6");
                });

            migrationBuilder.CreateTable(
                name: "memberships",
                schema: "clubs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    club_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    role = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    joined_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_memberships", x => x.id);
                    table.CheckConstraint("ck_club_memberships_role", "role IN ('owner', 'coach', 'member')");
                    table.ForeignKey(
                        name: "fk_memberships_clubs_club_id",
                        column: x => x.club_id,
                        principalSchema: "clubs",
                        principalTable: "clubs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_memberships_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_clubs_join_code",
                schema: "clubs",
                table: "clubs",
                column: "join_code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_clubs_name",
                schema: "clubs",
                table: "clubs",
                column: "name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_memberships_club_id",
                schema: "clubs",
                table: "memberships",
                column: "club_id");

            migrationBuilder.CreateIndex(
                name: "ix_memberships_user_id",
                schema: "clubs",
                table: "memberships",
                column: "user_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "memberships",
                schema: "clubs");

            migrationBuilder.DropTable(
                name: "clubs",
                schema: "clubs");
        }
    }
}
