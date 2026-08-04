using System.Text;
using System.Text.Json.Serialization;
using HRModule.Api.Data;
using HRModule.Api.Middleware;
using HRModule.Api.Security;
using HRModule.Api.Services;
using HRModule.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// ---- Services --------------------------------------------------------------
builder.Services.AddControllers()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        o.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
        o.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    });

builder.Services.AddDbContext<HRDbContext>(opt =>
    opt.UseOracle(builder.Configuration.GetConnectionString("HRModule")));

builder.Services.AddScoped<IEmployeeService, EmployeeService>();
builder.Services.AddScoped<IOrgService, OrgService>();
builder.Services.AddScoped<ITimeService, TimeService>();
builder.Services.AddScoped<IValueHelpService, ValueHelpService>();

// ---- Authentication (JWT) ----
var jwtOptions = builder.Configuration.GetSection("Jwt").Get<JwtOptions>() ?? new JwtOptions();
builder.Services.AddSingleton(jwtOptions);
builder.Services.AddSingleton<JwtTokenService>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidAudience = jwtOptions.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.Key)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorization(o =>
{
    o.AddPolicy(Policies.AdminOnly, p => p.RequireRole(Roles.Admin));
    o.AddPolicy(Policies.TimeKeepers, p => p.RequireRole(Roles.Admin, Roles.Manager));
    o.AddPolicy(Policies.AllStaff, p => p.RequireRole(Roles.Admin, Roles.Manager, Roles.Employee));
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
    c.SwaggerDoc("v1", new() { Title = "HR Module API", Version = "v1",
        Description = "SAP ECC 6.0 EHP8-style HCM module (PA, OM, PT) - C# / Oracle backend for SAPUI5." }));

var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                  ?? new[] { "http://localhost:8080" };
builder.Services.AddCors(o => o.AddPolicy("ui5", p =>
    p.WithOrigins(corsOrigins).AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

// ---- Pipeline --------------------------------------------------------------
app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "HR Module API v1"));
}

app.UseCors("ui5");

// This backend is a PURE REST API — it does not serve any front end. The
// SAPUI5 web app under ../frontend is a separate application (its own origin)
// that calls these endpoints over HTTP; cross-origin calls are allowed via the
// CORS policy above (configure Cors:AllowedOrigins for your front-end origin).

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "UP", module = "HCM", time = DateTime.UtcNow }));

// Root returns API metadata only (no UI) so the API-only nature is explicit.
app.MapGet("/", () => Results.Ok(new
{
    name = "HR Module REST API",
    module = "HCM (PA · OM · PT)",
    version = "v1",
    docs = "/swagger",
    health = "/health",
    note = "REST API only — the SAPUI5 front end is a separate application that calls this API."
}));

app.Run();
