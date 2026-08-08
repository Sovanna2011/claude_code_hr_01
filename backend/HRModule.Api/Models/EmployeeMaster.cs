namespace HRModule.Api.Models;

/// <summary>
/// Employee master anchor (PERNR). Holds referential integrity for all
/// infotypes and a small amount of denormalised master information.
/// </summary>
public class EmployeeMaster
{
    public int PERNR { get; set; }
    public DateTime? HireDate { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedOn { get; set; }
    public string? CreatedBy { get; set; }     // audit: created by (user)
    public DateTime? ChangedOn { get; set; }   // audit: last updated date/time (UTC)
    public string? ChangedBy { get; set; }     // audit: last changed by (user)
}
