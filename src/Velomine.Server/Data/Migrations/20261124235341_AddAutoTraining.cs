using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAutoTraining : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "plans",
                schema: "training",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    goal = table.Column<string>(type: "text", nullable: false),
                    days = table.Column<int[]>(type: "integer[]", nullable: false),
                    hours_per_week = table.Column<int>(type: "integer", nullable: false),
                    long_ride_day = table.Column<int>(type: "integer", nullable: true),
                    last_planned_for = table.Column<DateOnly>(type: "date", nullable: true),
                    is_on = table.Column<bool>(type: "boolean", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_plans", x => x.user_id);
                    table.CheckConstraint("ck_training_plans_days", "cardinality(days) BETWEEN 1 AND 7 AND days <@ ARRAY[0,1,2,3,4,5,6]::integer[]");
                    table.CheckConstraint("ck_training_plans_goal", "goal IN ('aerobic', 'fitter', 'faster', 'event', 'keep')");
                    table.CheckConstraint("ck_training_plans_hours", "hours_per_week BETWEEN 1 AND 30");
                    table.CheckConstraint("ck_training_plans_long_ride_day", "long_ride_day IS NULL OR long_ride_day BETWEEN 0 AND 6");
                    table.ForeignKey(
                        name: "fk_plans_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "sessions",
                schema: "training",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    local_date = table.Column<DateOnly>(type: "date", nullable: false),
                    recipe = table.Column<string>(type: "text", nullable: false),
                    block_percents = table.Column<int[]>(type: "integer[]", nullable: false),
                    state = table.Column<string>(type: "text", nullable: false),
                    skip_reason = table.Column<string>(type: "text", nullable: true),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_sessions", x => x.id);
                    table.CheckConstraint("ck_training_sessions_blocks", "cardinality(block_percents) BETWEEN 1 AND 20");
                    table.CheckConstraint("ck_training_sessions_recipe", "length(recipe) BETWEEN 2 AND 8");
                    table.CheckConstraint("ck_training_sessions_skip_reason", "skip_reason IS NULL OR skip_reason IN ('tired', 'ill', 'no_time', 'other')");
                    table.CheckConstraint("ck_training_sessions_skip_reason_only_when_skipped", "skip_reason IS NULL OR state = 'skipped'");
                    table.CheckConstraint("ck_training_sessions_state", "state IN ('planned', 'done', 'easy', 'moved', 'skipped', 'missed')");
                    table.ForeignKey(
                        name: "fk_sessions_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_sessions_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_sessions_ride_id",
                schema: "training",
                table: "sessions",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_sessions_user_id_local_date",
                schema: "training",
                table: "sessions",
                columns: new[] { "user_id", "local_date" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "plans",
                schema: "training");

            migrationBuilder.DropTable(
                name: "sessions",
                schema: "training");
        }
    }
}
