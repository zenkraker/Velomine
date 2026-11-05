using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class Profile_Goals_Notifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "analytics");

            migrationBuilder.EnsureSchema(
                name: "notifications");

            migrationBuilder.AddColumn<int>(
                name: "first_day_of_week",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: false,
                defaultValue: 1); // Monday, for accounts made before this column (DayOfWeek.Monday)

            migrationBuilder.AddColumn<int>(
                name: "ftp_w",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "max_heart_rate",
                schema: "accounts",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "time_zone",
                schema: "accounts",
                table: "users",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "weight_kg",
                schema: "accounts",
                table: "users",
                type: "double precision",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "goals",
                schema: "analytics",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    period = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    metric = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    target = table.Column<double>(type: "double precision", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_goals", x => x.id);
                    table.CheckConstraint("ck_goals_metric", "metric IN ('distance', 'elevation', 'time', 'rides')");
                    table.CheckConstraint("ck_goals_period", "period IN ('week', 'month', 'year')");
                    table.CheckConstraint("ck_goals_target", "target > 0");
                    table.ForeignKey(
                        name: "fk_goals_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "notifications",
                schema: "notifications",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    type = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    subject = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    ride_id = table.Column<Guid>(type: "uuid", nullable: true),
                    bike_id = table.Column<Guid>(type: "uuid", nullable: true),
                    component_id = table.Column<Guid>(type: "uuid", nullable: true),
                    about_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    read_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_notifications", x => x.id);
                    table.ForeignKey(
                        name: "fk_notifications_bike_components_component_id",
                        column: x => x.component_id,
                        principalSchema: "bikes",
                        principalTable: "bike_components",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_notifications_bikes_bike_id",
                        column: x => x.bike_id,
                        principalSchema: "bikes",
                        principalTable: "bikes",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_notifications_rides_ride_id",
                        column: x => x.ride_id,
                        principalSchema: "rides",
                        principalTable: "rides",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_notifications_users_about_user_id",
                        column: x => x.about_user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_notifications_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "accounts",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_first_day_of_week",
                schema: "accounts",
                table: "users",
                sql: "first_day_of_week BETWEEN 0 AND 6");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_ftp_w",
                schema: "accounts",
                table: "users",
                sql: "ftp_w BETWEEN 30 AND 1000");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_max_heart_rate",
                schema: "accounts",
                table: "users",
                sql: "max_heart_rate BETWEEN 100 AND 240");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_weight_kg",
                schema: "accounts",
                table: "users",
                sql: "weight_kg BETWEEN 20 AND 300");

            migrationBuilder.CreateIndex(
                name: "ix_goals_user_id_period_metric",
                schema: "analytics",
                table: "goals",
                columns: new[] { "user_id", "period", "metric" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_notifications_about_user_id",
                schema: "notifications",
                table: "notifications",
                column: "about_user_id");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_bike_id",
                schema: "notifications",
                table: "notifications",
                column: "bike_id");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_component_id",
                schema: "notifications",
                table: "notifications",
                column: "component_id");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_ride_id",
                schema: "notifications",
                table: "notifications",
                column: "ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_user_id_created_at",
                schema: "notifications",
                table: "notifications",
                columns: new[] { "user_id", "created_at" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "goals",
                schema: "analytics");

            migrationBuilder.DropTable(
                name: "notifications",
                schema: "notifications");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_first_day_of_week",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_ftp_w",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_max_heart_rate",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_weight_kg",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "first_day_of_week",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "ftp_w",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "max_heart_rate",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "time_zone",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "weight_kg",
                schema: "accounts",
                table: "users");
        }
    }
}
