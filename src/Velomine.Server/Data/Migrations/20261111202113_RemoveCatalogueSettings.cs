using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Velomine.Server.Data.Migrations
{
    /// <summary>
    /// The code stopped using <c>bikes.catalogue_settings</c>: contributions are on whenever a publisher is
    /// configured. Migrations move forward, so the table is not dropped in the release that stops using it — it stays
    /// until a deployment no longer reads it, then a later migration drops it by hand. The model snapshot no longer
    /// knows the table, so nothing will propose that drop automatically.
    /// </summary>
    public partial class RemoveCatalogueSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
