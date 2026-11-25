namespace Velomine.Server.Features.Training;

/// <summary>
/// One line the planner puts on a week, in both languages, with the code the app reads. The words are the ones the
/// owner approved in `docs/design/pages/training/TrainingNames.md`; a change there changes this.
/// </summary>
public sealed record TrainingNote(string Code, string English, string Italian);

/// <summary>
/// The words the rider reads about a planned week. The planner's own terms never reach the rider: the lighter week is an
/// "Easy week", and the gentle base block is never named at all — only the line that it gets more personal as the rides
/// come in (TrainingNames.md).
/// </summary>
public static class TrainingNotes
{
    /// <summary>The lighter week, and the one sentence it shows.</summary>
    public static readonly TrainingNote EasyWeek = new(
        "easy_week",
        "Easy week: your body gets stronger while it rests",
        "Settimana facile: il tuo corpo diventa più forte mentre riposa");

    /// <summary>The gentle base block, which is never named: this line is all the rider reads of it.</summary>
    public static readonly TrainingNote MorePersonal = new(
        "more_personal",
        "It gets more personal as your rides come in",
        "Diventa più personale man mano che arrivano i tuoi giri");

    public static readonly TrainingNote[] All = [EasyWeek, MorePersonal];

    public static TrainingNote? ByCode(string? code) => All.FirstOrDefault(n => n.Code == code);
}
