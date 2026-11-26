using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <inheritdoc />
    public partial class HeartRateSourceOnUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "max_heart_rate_ride_id",
                schema: "accounts",
                table: "users",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "max_heart_rate_source",
                schema: "accounts",
                table: "users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "threshold_heart_rate_ride_id",
                schema: "accounts",
                table: "users",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "threshold_heart_rate_source",
                schema: "accounts",
                table: "users",
                type: "text",
                nullable: true);

            // The value each member has now is the truth; the newest history row of that kind says how it got there.
            // Only a row whose bpm still equals the number, and that was not cleared, makes it measured; the ride is
            // joined rather than read, because it may no longer exist.
            migrationBuilder.Sql("""
                UPDATE accounts.users u
                SET max_heart_rate_source = h.source,
                    max_heart_rate_ride_id = r.id
                FROM (
                    SELECT DISTINCT ON (user_id) user_id, bpm, source, ride_id
                    FROM accounts.heart_rate_history
                    WHERE kind = 'max'
                    ORDER BY user_id, set_at DESC, sequence DESC
                ) h
                LEFT JOIN rides.rides r ON r.id = h.ride_id
                WHERE h.user_id = u.id
                  AND u.max_heart_rate_bpm = h.bpm
                  AND h.source <> 'cleared';

                UPDATE accounts.users u
                SET threshold_heart_rate_source = h.source,
                    threshold_heart_rate_ride_id = r.id
                FROM (
                    SELECT DISTINCT ON (user_id) user_id, bpm, source, ride_id
                    FROM accounts.heart_rate_history
                    WHERE kind = 'threshold'
                    ORDER BY user_id, set_at DESC, sequence DESC
                ) h
                LEFT JOIN rides.rides r ON r.id = h.ride_id
                WHERE h.user_id = u.id
                  AND u.threshold_heart_rate_bpm = h.bpm
                  AND h.source <> 'cleared';
                """);

            // Every other set number was typed: nothing in the history says a ride measured it.
            migrationBuilder.Sql("""
                UPDATE accounts.users
                SET max_heart_rate_source = 'manual'
                WHERE max_heart_rate_bpm IS NOT NULL AND max_heart_rate_source IS NULL;

                UPDATE accounts.users
                SET threshold_heart_rate_source = 'manual'
                WHERE threshold_heart_rate_bpm IS NOT NULL AND threshold_heart_rate_source IS NULL;
                """);

            migrationBuilder.CreateIndex(
                name: "ix_users_max_heart_rate_ride_id",
                schema: "accounts",
                table: "users",
                column: "max_heart_rate_ride_id");

            migrationBuilder.CreateIndex(
                name: "ix_users_threshold_heart_rate_ride_id",
                schema: "accounts",
                table: "users",
                column: "threshold_heart_rate_ride_id");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_max_heart_rate_ride",
                schema: "accounts",
                table: "users",
                sql: "max_heart_rate_ride_id IS NULL OR max_heart_rate_source = 'measured'");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_max_heart_rate_source",
                schema: "accounts",
                table: "users",
                sql: "(max_heart_rate_bpm IS NULL) = (max_heart_rate_source IS NULL)");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_max_heart_rate_source_value",
                schema: "accounts",
                table: "users",
                sql: "max_heart_rate_source IN ('manual', 'measured')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_threshold_heart_rate_ride",
                schema: "accounts",
                table: "users",
                sql: "threshold_heart_rate_ride_id IS NULL OR threshold_heart_rate_source = 'measured'");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_threshold_heart_rate_source",
                schema: "accounts",
                table: "users",
                sql: "(threshold_heart_rate_bpm IS NULL) = (threshold_heart_rate_source IS NULL)");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_threshold_heart_rate_source_value",
                schema: "accounts",
                table: "users",
                sql: "threshold_heart_rate_source IN ('manual', 'measured')");

            migrationBuilder.AddForeignKey(
                name: "fk_users_rides_max_heart_rate_ride_id",
                schema: "accounts",
                table: "users",
                column: "max_heart_rate_ride_id",
                principalSchema: "rides",
                principalTable: "rides",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "fk_users_rides_threshold_heart_rate_ride_id",
                schema: "accounts",
                table: "users",
                column: "threshold_heart_rate_ride_id",
                principalSchema: "rides",
                principalTable: "rides",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_users_rides_max_heart_rate_ride_id",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropForeignKey(
                name: "fk_users_rides_threshold_heart_rate_ride_id",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropIndex(
                name: "ix_users_max_heart_rate_ride_id",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropIndex(
                name: "ix_users_threshold_heart_rate_ride_id",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_max_heart_rate_ride",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_max_heart_rate_source",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_max_heart_rate_source_value",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_threshold_heart_rate_ride",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_threshold_heart_rate_source",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_threshold_heart_rate_source_value",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "max_heart_rate_ride_id",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "max_heart_rate_source",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "threshold_heart_rate_ride_id",
                schema: "accounts",
                table: "users");

            migrationBuilder.DropColumn(
                name: "threshold_heart_rate_source",
                schema: "accounts",
                table: "users");
        }
    }
}
