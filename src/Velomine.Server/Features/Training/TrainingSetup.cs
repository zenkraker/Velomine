namespace Velomine.Server.Features.Training;

/// <summary>
/// Bound from "Velomine:Training" (environment: VELOMINE__TRAINING__AUTOENABLED). It is the operator's switch, not
/// the member's: off, the switch, the Training destination and the nightly planning disappear, and stored plans stay.
/// </summary>
public sealed class TrainingOptions
{
    public bool AutoEnabled { get; set; } = true;
}

public static class TrainingSetup
{
    public static IServiceCollection AddTraining(this IServiceCollection services, IConfiguration configuration)
    {
        // ValidateOnStart makes a value that is not a boolean fail at startup instead of on the first request.
        services.AddOptions<TrainingOptions>().BindConfiguration("Velomine:Training").ValidateOnStart();
        return services;
    }
}
