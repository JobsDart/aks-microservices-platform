using System.Text;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Service identity comes from an env var so one image can run as any of the platform's services.
var serviceName = Environment.GetEnvironmentVariable("SERVICE_NAME") ?? "sample-service";
var startedUtc = DateTimeOffset.UtcNow;
long requestCount = 0;

// Count every request — exposed as a Prometheus counter on /metrics.
app.Use(async (ctx, next) =>
{
    Interlocked.Increment(ref requestCount);
    await next();
});

app.MapGet("/", () => Results.Ok(new { service = serviceName, status = "ok" }));

// Kubernetes liveness/readiness probe target.
app.MapGet("/health", () => Results.Ok(new { status = "healthy", service = serviceName }));

// Prometheus scrape target (text exposition format v0.0.4).
app.MapGet("/metrics", () =>
{
    var uptime = (DateTimeOffset.UtcNow - startedUtc).TotalSeconds;
    var sb = new StringBuilder();
    sb.AppendLine("# HELP app_requests_total Total HTTP requests handled.");
    sb.AppendLine("# TYPE app_requests_total counter");
    sb.AppendLine($"app_requests_total{{service=\"{serviceName}\"}} {Interlocked.Read(ref requestCount)}");
    sb.AppendLine("# HELP app_uptime_seconds Seconds since process start.");
    sb.AppendLine("# TYPE app_uptime_seconds gauge");
    sb.AppendLine($"app_uptime_seconds{{service=\"{serviceName}\"}} {uptime:F0}");
    return Results.Text(sb.ToString(), "text/plain; version=0.0.4");
});

app.Run();
