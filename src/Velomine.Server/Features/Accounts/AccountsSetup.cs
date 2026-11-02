using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

public static class AccountsSetup
{
    public static IServiceCollection AddAccounts(this IServiceCollection services)
    {
        services.AddOptions<AccountsOptions>().BindConfiguration("Velomine:Accounts");
        services.AddOptions<AdminBootstrapOptions>().BindConfiguration("Velomine:Admin");
        services.AddSingleton(TimeProvider.System);

        // Cookie for the web app, bearer token for the mobile app and tools. The Identity endpoints
        // themselves are not mapped: the slices in Features/Accounts own the routes.
        services.AddIdentityApiEndpoints<User>(o =>
            {
                o.User.RequireUniqueEmail = true;
                o.Password.RequiredLength = 10;
                o.Password.RequireNonAlphanumeric = false;
                o.Lockout.MaxFailedAccessAttempts = 5;
            })
            .AddRoles<IdentityRole<Guid>>()
            .AddEntityFrameworkStores<VelomineDbContext>()
            .AddSignInManager<VelomineSignInManager>();
        services.AddAuthorization();
        services.AddHostedService<AccountsStartup>();
        return services;
    }
}

/// <summary>On start: apply migrations, make sure the roles exist, create the first admin if configured.</summary>
public sealed class AccountsStartup(IServiceProvider services, ILogger<AccountsStartup> logger) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        await db.Database.MigrateAsync(cancellationToken);

        var roles = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        foreach (var role in Roles.All)
            if (!await roles.RoleExistsAsync(role))
                await roles.CreateAsync(new IdentityRole<Guid>(role));

        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        if ((await users.GetUsersInRoleAsync(Roles.Admin)).Count > 0) return;

        var admin = scope.ServiceProvider.GetRequiredService<IOptions<AdminBootstrapOptions>>().Value;
        if (string.IsNullOrWhiteSpace(admin.Email) || string.IsNullOrWhiteSpace(admin.Password))
        {
            logger.LogWarning("No admin exists. Set Velomine__Admin__Email and Velomine__Admin__Password to create one.");
            return;
        }

        var user = new User
        {
            UserName = admin.Email,
            Email = admin.Email,
            DisplayName = "Admin",
            IsApproved = true,
            CreatedAt = scope.ServiceProvider.GetRequiredService<TimeProvider>().GetUtcNow(),
        };
        var created = await users.CreateAsync(user, admin.Password);
        if (!created.Succeeded)
            throw new InvalidOperationException("Could not create the admin: " + string.Join("; ", created.Errors.Select(e => e.Description)));
        await users.AddToRolesAsync(user, [Roles.Admin, Roles.Member]);
        logger.LogInformation("Created the admin account {Email}.", admin.Email);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
