using System.Reflection;
using AgentEval.MAF;
using AgentEval.RedTeam;
using AgentEval.RedTeam.Reporting;

namespace MafDemo;

/// <summary>
/// A light AgentEval red-team scan: three OWASP LLM attacks, Quick intensity, a few probes each, no LLM judge
/// (AgentEval's deterministic oracles). Note: MAFAgentAdapter is a text-only SUT, so IndirectInjection delivers
/// its payload through the user message; the hand-built poisoned-tool probe in Evaluation.cs covers tool output.
/// </summary>
internal static class RedTeamScan
{
    public static async Task<int> RunAsync(DemoConfig cfg, int maxProbesPerAttack)
    {
        Console.WriteLine($"AgentEval {AgentEvalVersion} red-team scan: PromptInjection, IndirectInjection, SystemPromptExtraction; Quick, max {maxProbesPerAttack} probes each");

        var sut = new MAFAgentAdapter(AgentFactory.CreateAgent(cfg));
        var result = await AttackPipeline.Create()
            .WithAttack(Attack.PromptInjection)
            .WithAttack(Attack.IndirectInjection)
            .WithAttack(Attack.SystemPromptExtraction)
            .WithIntensity(Intensity.Quick)
            .WithMaxProbesPerAttack(maxProbesPerAttack)
            .WithTimeoutPerProbe(TimeSpan.FromMinutes(2))
            .ScanAsync(sut);

        Directory.CreateDirectory(cfg.OutDir);
        var json = Path.Combine(cfg.OutDir, $"redteam-report-{cfg.Harness}.json");
        var md = Path.Combine(cfg.OutDir, $"redteam-report-{cfg.Harness}.md");
        await new JsonReportExporter().ExportToFileAsync(result, json);
        await new MarkdownReportExporter().ExportToFileAsync(result, md);

        Console.WriteLine();
        Console.WriteLine($"passed={result.Passed} overallScore={result.OverallScore} attackSuccessRate={result.AttackSuccessRate}");
        Console.WriteLine($"probes: planned={result.PlannedProbes} resisted={result.ResistedProbes} conclusive={result.ConclusiveProbes} inconclusive={result.InconclusiveProbes} errored={result.ErroredProbes}");
        Console.WriteLine($"wrote {json} and {md}");
        return 0;
    }

    public static string AgentEvalVersion =>
        typeof(AttackPipeline).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion.Split('+')[0]
        ?? typeof(AttackPipeline).Assembly.GetName().Version?.ToString() ?? "unknown";
}
