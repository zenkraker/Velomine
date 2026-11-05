using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

public static class AccountsSetup
{
    public static IServiceCollection AddAccounts(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<AccountsOptions>().BindConfiguration("Velomine:Accounts");
        services.AddOptions<AdminBootstrapOptions>().BindConfiguration("Velomine:Admin");
        services.AddOptions<SsoOptions>().BindConfiguration("Velomine:Sso");
        services.AddSingleton(TimeProvider.System);
        services.AddMemoryCache();
        services.AddSingleton<SsoAppCodes>();
        services.AddScoped<AccountDeletion>();
        services.AddScoped<AccountExport>();
        services.AddSingleton<ExportTokens>();

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
        AddSso(services, configuration.GetSection("Velomine:Sso").Get<SsoOptions>() ?? new SsoOptions());
        services.AddHostedService<AccountsStartup>();
        return services;
    }

    // The provider's settings are read now because the OpenID Connect handler must be registered at startup.
    private static void AddSso(IServiceCollection services, SsoOptions sso)
    {
        if (!sso.Enabled) return;

        // Identity already provides the short-lived external cookie the provider sign-in lands in.
        services.AddAuthentication().AddOpenIdConnect(SsoOptions.Scheme, o =>
        {
            o.SignInScheme = IdentityConstants.ExternalScheme;
            o.Authority = sso.Authority;
            o.ClientId = sso.ClientId;
            o.ClientSecret = sso.ClientSecret;
            o.RequireHttpsMetadata = !sso.AllowInsecureHttp;
            o.ResponseType = OpenIdConnectResponseType.Code;
            // A plain top-level redirect back (not a cross-site form post), so Lax cookies work on http and https.
            o.ResponseMode = OpenIdConnectResponseMode.Query;
            o.CorrelationCookie.SameSite = SameSiteMode.Lax;
            o.NonceCookie.SameSite = SameSiteMode.Lax;
            // These cookies are Secure by default, which an http development setup cannot send back. Only relax it there.
            if (sso.AllowInsecureHttp)
            {
                o.CorrelationCookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
                o.NonceCookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
            }

            o.UsePkce = true;
            o.GetClaimsFromUserInfoEndpoint = true;
            o.SaveTokens = false;
            o.MapInboundClaims = false; // keep the standard claim names: sub, email, name, email_verified
            o.Scope.Clear();
            o.Scope.Add("openid");
            o.Scope.Add("profile");
            o.Scope.Add("email");
        });
    }
}

/// <summary>On start: make sure the roles exist and create the first admin if configured. Runs after the migrations.</summary>
public sealed class AccountsStartup(IServiceProvider services, ILogger<AccountsStartup> logger) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using var scope = services.CreateAsyncScope();
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
