using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRideImports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "import_id",
                schema: "rides",
                table: "rides",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "source",
                schema: "rides",
                table: "rides",
                type: "character varying(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "source_id",
                schema: "rides",
                table: "rides",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "imports",
                schema: "rides",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    source = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    archive_sha256 = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    file_name = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    total = table.Column<int>(type: "integer", nullable: false),
                    error = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    finished_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_imports", x => x.id);
                    table.ForeignKey(
                        name: "fk_imports_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_rides_import_id",
                schema: "rides",
                table: "rides",
                column: "import_id");

            migrationBuilder.CreateIndex(
                name: "ux_rides_user_source",
                schema: "rides",
                table: "rides",
                columns: new[] { "user_id", "source", "source_id" },
                unique: true,
                filter: "source IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "ix_imports_user_id_archive_sha256",
                schema: "rides",
                table: "imports",
                columns: new[] { "user_id", "archive_sha256" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_imports_user_id_created_at",
                schema: "rides",
                table: "imports",
                columns: new[] { "user_id", "created_at" });

            migrationBuilder.AddForeignKey(
                name: "fk_rides_imports_import_id",
                schema: "rides",
                table: "rides",
                column: "import_id",
                principalSchema: "rides",
                principalTable: "imports",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_rides_imports_import_id",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropTable(
                name: "imports",
                schema: "rides");

            migrationBuilder.DropIndex(
                name: "ix_rides_import_id",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropIndex(
                name: "ux_rides_user_source",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "import_id",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "source",
                schema: "rides",
                table: "rides");

            migrationBuilder.DropColumn(
                name: "source_id",
                schema: "rides",
                table: "rides");
        }
    }
}
