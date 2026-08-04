using System.ComponentModel.DataAnnotations;

namespace HRModule.Api.DTOs;

/// <summary>A leave request as shown in the leave worklist.</summary>
public class LeaveRequestDto
{
    public int RequestId { get; set; }
    public int Pernr { get; set; }
    public string? EmployeeName { get; set; }
    public string LeaveTypeKey { get; set; } = string.Empty; // AWART
    public string? LeaveType { get; set; }                   // resolved text (T554S)
    public DateTime Begda { get; set; }
    public DateTime Endda { get; set; }
    public decimal Days { get; set; }
    public string Status { get; set; } = "Pending";
    public string? Note { get; set; }
    public DateTime RequestedOn { get; set; }
    public string? DecidedBy { get; set; }
    public DateTime? DecidedOn { get; set; }
}

/// <summary>Payload for an employee (ESS) to submit a leave request.</summary>
public class CreateLeaveRequest
{
    [Required] public string LeaveType { get; set; } = string.Empty; // AWART
    [Required] public DateTime Begda { get; set; }
    [Required] public DateTime Endda { get; set; }
    public decimal? Days { get; set; }   // optional; calculated from dates when omitted
    [MaxLength(200)] public string? Note { get; set; }
}

/// <summary>Payload for a manager/HR (MSS) to approve or reject a request.</summary>
public class LeaveDecisionRequest
{
    [Required] public bool Approve { get; set; }
    public string DecidedBy { get; set; } = "WEBUI";
}
