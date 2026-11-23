namespace MafDemo;

/// <summary>
/// Runtime configuration, read only from environment variables so the same image runs
/// against local Ollama or a hosted Nemotron endpoint without rebuilding.
/// </summary>
internal sealed record DemoConfig(string BaseUrl, string Model, string ApiKey, string ApiKeySource, float Temperature, string OutDir, string Harness, int MaxOutputTokens)
{
    public static DemoConfig FromEnvironment()
    {
        var baseUrl = Env("OPENAI_BASE_URL") ?? "http://host.openshell.internal:11434/v1";
        var model = Env("MODEL") ?? "nemotron-3-nano:4b";

        // Never a real key in code, images or logs. Inside OpenShell a provider exposes only a
        // placeholder in the sandbox environment; the gateway's proxy swaps in the real credential
        // at egress, and only for the endpoints and binaries the provider profile allows.
        // Ollama ignores the key entirely.
        var (apiKey, source) = Env("NVIDIA_API_KEY") is { } nv ? (nv, "NVIDIA_API_KEY")
            : Env("OPENROUTER_API_KEY") is { } or ? (or, "OPENROUTER_API_KEY")
            : ("unused", "none (local Ollama)");

        var temperature = float.TryParse(Env("TEMPERATURE"), System.Globalization.CultureInfo.InvariantCulture, out var t) ? t : 0.3f;
        var outDir = Env("OUT_DIR") ?? (OperatingSystem.IsWindows() ? "out" : "/tmp/mafdemo");
        // v1: lookup_cwe takes a CWE id (the model must remember CWE numbers).
        // v2: lookup_cwe searches by weakness name or id (the harness supplies the knowledge).
        var harness = Env("HARNESS") is "v1" ? "v1" : "v2";
        var maxTokens = int.TryParse(Env("MAX_OUTPUT_TOKENS"), out var mt) ? mt : 2048;
        return new DemoConfig(baseUrl, model, apiKey, source, temperature, outDir, harness, maxTokens);
    }

    /// <summary>Describes the key without revealing it: real NVIDIA keys start with "nvapi-", OpenRouter keys with "sk-or-".</summary>
    public string KeyVisibility => ApiKey switch
    {
        "unused" => "no key needed",
        _ when ApiKey.StartsWith("nvapi-", StringComparison.Ordinal) || ApiKey.StartsWith("sk-or-", StringComparison.Ordinal)
            => "WARNING: a real-looking key is visible to this process",
        _ => $"placeholder only ({ApiKey.Length} chars, not a real key format)",
    };

    private static string? Env(string name) => Environment.GetEnvironmentVariable(name) is { Length: > 0 } v ? v : null;
}
