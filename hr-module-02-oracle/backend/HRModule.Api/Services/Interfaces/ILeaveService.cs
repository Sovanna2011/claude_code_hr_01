using HRModule.Api.DTOs;

namespace HRModule.Api.Services.Interfaces;

/// <summary>
/// Leave-management workflow: submit requests (ESS), list them, and approve /
/// reject them (MSS/HR). Approval posts the absence and deducts the quota.
/// </summary>
public interface ILeaveService
{
    /// <summary>Lists leave requests; when <paramref name="pernr"/> is set, only that employee's.</summary>
    Task<IReadOnlyList<LeaveRequestDto>> GetRequestsAsync(int? pernr, CancellationToken ct = default);

    /// <summary>Submits a new (Pending) leave request for an employee.</summary>
    Task<LeaveRequestDto> CreateRequestAsync(int pernr, CreateLeaveRequest request, CancellationToken ct = default);

    /// <summary>
    /// Approves or rejects a pending request. Approval records IT2001 and deducts
    /// the matching IT2006 quota. Returns false if the request does not exist.
    /// </summary>
    Task<bool> DecideAsync(int requestId, LeaveDecisionRequest request, CancellationToken ct = default);
}
