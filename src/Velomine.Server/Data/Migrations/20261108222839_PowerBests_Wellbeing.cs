using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class PowerBests_Wellbeing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_share_grants_data_type",
                schema: "sharing",
                table: "grants");

            migrationBuilder.EnsureSchema(
                name: "wellbeing");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "wellbeing_consent_at",
                schema: "accounts",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "wellbeing_consent_version",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "daily_check_ins",
                schema: "wellbeing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    local_date = table.Column<DateOnly>(type: "date", nullable: false),
                    fatigue = table.Column<int>(type: "integer", nullable: false),
                    soreness = table.Column<int>(type: "integer", nullable: false),
                    mood = table.Column<int>(type: "integer", nullable: false),
                    stress = table.Column<int>(type: "integer", nullable: false),
                    motivation = table.Column<int>(type: "integer", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_daily_check_ins", x => x.id);
                    table.CheckConstraint("ck_daily_check_ins_fatigue", "fatigue BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_daily_check_ins_mood", "mood BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_daily_check_ins_motivation", "motivation BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_daily_check_ins_soreness", "soreness BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_daily_check_ins_stress", "stress BETWEEN 1 AND 5");
                    table.ForeignKey(
                        name: "fk_daily_check_ins_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ride_feel",
                schema: "wellbeing",
                columns: table => new
                {
                    ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    rpe = table.Column<int>(type: "integer", nullable: false),
                    notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ride_feel", x => x.ride_id);
                    table.CheckConstraint("ck_ride_feel_rpe", "rpe BETWEEN 1 AND 10");
                    table.ForeignKey(
                        name: "fk_ride_feel_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ride_power_bests",
                schema: "rides",
                columns: table => new
                {
                    ride_id = table.Column<Guid>(type: "uuid", nullable: false),
                    duration_s = table.Column<int>(type: "integer", nullable: false),
                    watts = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ride_power_bests", x => new { x.ride_id, x.duration_s });
                    table.ForeignKey(
                        name: "fk_ride_power_bests_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddCheckConstraint(
                name: "ck_share_grants_data_type",
                schema: "sharing",
                table: "grants",
                sql: "data_type IN ('rides', 'analytics', 'routes', 'wellbeing')");

            migrationBuilder.CreateIndex(
                name: "ix_daily_check_ins_user_id_local_date",
                schema: "wellbeing",
                table: "daily_check_ins",
                columns: new[] { "user_id", "local_date" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "daily_check_ins",
                schema: "wellbeing");

            migrationBuilder.DropTable(
                name: "ride_feel",
                schema: "wellbeing");

            migrationBuilder.DropTable(
                name: "ride_power_bests",
                schema: "rides");

            migrationBuilder.DropCheckConstraint(
                name: "ck_share_grants_data_type",
                schema: "sharing",
                table: "grants");

            migrationBuilder.DropColumn(
                name: "wellbeing_consent_at",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "wellbeing_consent_version",
                schema: "accounts",
                table: "users");

            migrationBuilder.AddCheckConstraint(
                name: "ck_share_grants_data_type",
                schema: "sharing",
                table: "grants",
                sql: "data_type IN ('rides', 'analytics', 'routes')");
        }
    }
}
