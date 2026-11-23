using System.Diagnostics;
using System.Text.Json;
using OpenTelemetry;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace MafDemo;

internal static class Tracing
{
    public const string SourceName = "MafDemo";
    public static readonly ActivitySource Source = new(SourceName);

    /// <summary>Exports agent, chat and tool spans (MAF + Microsoft.Extensions.AI) to a JSON Lines file.</summary>
    public static TracerProvider Start(string path) =>
        Sdk.CreateTracerProviderBuilder()
            .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("MafDemo"))
            .AddSource(SourceName, "Microsoft.Agents.AI*", "Experimental.Microsoft.Agents.AI*", "Microsoft.Extensions.AI*", "Experimental.Microsoft.Extensions.AI*")
            .AddProcessor(new SimpleActivityExportProcessor(new JsonlFileExporter(path)))
            .Build()!;
}

/// <summary>Minimal file exporter: one JSON object per finished span.</summary>
internal sealed class JsonlFileExporter : BaseExporter<Activity>
{
    private readonly StreamWriter _writer;

    public JsonlFileExporter(string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        _writer = new StreamWriter(path, append: true) { AutoFlush = true };
    }

    public override ExportResult Export(in Batch<Activity> batch)
    {
        foreach (var a in batch)
        {
            var record = new
            {
                traceId = a.TraceId.ToHexString(),
                spanId = a.SpanId.ToHexString(),
                parentSpanId = a.ParentSpanId == default ? null : a.ParentSpanId.ToHexString(),
                name = a.DisplayName,
                source = a.Source.Name,
                kind = a.Kind.ToString(),
                startUtc = a.StartTimeUtc,
                durationMs = Math.Round(a.Duration.TotalMilliseconds, 1),
                status = a.Status.ToString(),
                tags = a.TagObjects.GroupBy(t => t.Key).ToDictionary(g => g.Key, g => g.Last().Value?.ToString()),
                events = a.Events.Select(e => new { e.Name, e.Timestamp }).ToArray(),
            };
            _writer.WriteLine(JsonSerializer.Serialize(record));
        }
        return ExportResult.Success;
    }

    protected override bool OnShutdown(int timeoutMilliseconds)
    {
        _writer.Dispose();
        return true;
    }
}
