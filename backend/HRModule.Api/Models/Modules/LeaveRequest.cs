namespace HRModule.Api.Models.Modules;

/// <summary>
/// Leave-management request (ESS → MSS/HR workflow). On approval the app writes
/// an absence (IT2001) and deducts the matching absence quota (IT2006), mirroring
/// the SAP leave-request → time-evaluation link. Table [HR].[LeaveRequest].
/// </summary>
public class LeaveRequest
{
    public int RequestId { get; set; }
    public int PERNR { get; set; }
    public string AWART { get; set; } = string.Empty;   // leave (absence) type, T554S
    public DateTime BEGDA { get; set; }
    public DateTime ENDDA { get; set; }
    public decimal Days { get; set; }
    public string Status { get; set; } = "Pending";     // Pending / Approved / Rejected
    public string? Note { get; set; }
    public DateTime RequestedOn { get; set; }
    public string? DecidedBy { get; set; }
    public DateTime? DecidedOn { get; set; }
}
