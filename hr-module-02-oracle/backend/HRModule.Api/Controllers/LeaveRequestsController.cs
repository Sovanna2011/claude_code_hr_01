using System.Security.Claims;
using HRModule.Api.DTOs;
using HRModule.Api.Security;
using HRModule.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRModule.Api.Controllers;

/// <summary>
/// Leave-management endpoints (ESS/MSS workflow over IT2001/IT2006).
/// Employees submit and see their own requests; managers/HR see all and decide.
/// </summary>
[ApiController]
[Route("api/leave-requests")]
[Produces("application/json")]
[Authorize]
public class LeaveRequestsController : ControllerBase
{
    private readonly ILeaveService _service;

    public LeaveRequestsController(ILeaveService service) => _service = service;

    /// <summary>List leave requests. Employees see only their own; HR/managers see all.</summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<LeaveRequestDto>>> GetAll(CancellationToken ct)
    {
        int? scope = (User.IsInRole(Roles.Admin) || User.IsInRole(Roles.Manager)) ? null : OwnPernr();
        // An employee account not linked to a PERNR has nothing to show.
        if (scope is null && !(User.IsInRole(Roles.Admin) || User.IsInRole(Roles.Manager)))
            return Ok(Array.Empty<LeaveRequestDto>());
        return Ok(await _service.GetRequestsAsync(scope, ct));
    }

    /// <summary>Submit a leave request for the signed-in employee (ESS).</summary>
    [HttpPost]
    public async Task<ActionResult<LeaveRequestDto>> Create([FromBody] CreateLeaveRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        var pernr = OwnPernr();
        if (pernr is null)
            return BadRequest(new { message = "This account is not linked to an employee and cannot request leave." });
        var dto = await _service.CreateRequestAsync(pernr.Value, request, ct);
        return CreatedAtAction(nameof(GetAll), new { }, dto);
    }

    /// <summary>Approve or reject a pending request (MSS/HR). Admin or manager only.</summary>
    [HttpPost("{id:int}/decide")]
    [Authorize(Policy = Policies.TimeKeepers)]
    public async Task<IActionResult> Decide(int id, [FromBody] LeaveDecisionRequest request, CancellationToken ct)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        if (string.IsNullOrWhiteSpace(request.DecidedBy) || request.DecidedBy == "WEBUI")
            request.DecidedBy = User.Identity?.Name ?? "WEBUI";
        var ok = await _service.DecideAsync(id, request, ct);
        return ok ? NoContent() : NotFound(new { message = $"Leave request {id} not found." });
    }

    /// <summary>The signed-in user's own personnel number, if the account is linked to one.</summary>
    private int? OwnPernr()
    {
        var own = User.FindFirstValue(JwtTokenService.PernrClaim);
        return own is not null && int.TryParse(own, out var p) ? p : null;
    }
}
