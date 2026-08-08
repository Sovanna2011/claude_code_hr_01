namespace HRModule.Api.Models.Infotypes;

/// <summary>
/// Common key and administrative fields shared by every SAP PA infotype.
/// Mirrors the SAP structure PSKEY plus the administrative fields AEDTM/UNAME.
/// </summary>
public abstract class InfotypeBase
{
    /// <summary>Personnel number (PERNR).</summary>
    public int PERNR { get; set; }

    /// <summary>Subtype (SUBTY).</summary>
    // SAP initialises character key fields to SPACE, so the initial value for the
    // mandatory key fields SUBTY/OBJPS/SPRPS is a single space (matching the DDL
    // DEFAULT ' '), keeping the composite infotype primary key non-null.
    public string SUBTY { get; set; } = " ";

    /// <summary>Object identification (OBJPS).</summary>
    public string OBJPS { get; set; } = " ";

    /// <summary>Lock indicator (SPRPS); 'X' means the record is locked.</summary>
    public string SPRPS { get; set; } = " ";

    /// <summary>Start date of validity (BEGDA).</summary>
    public DateTime BEGDA { get; set; }

    /// <summary>End date of validity (ENDDA); 9999-12-31 = open ended.</summary>
    public DateTime ENDDA { get; set; } = new DateTime(9999, 12, 31);

    /// <summary>Sequence number (SEQNR).</summary>
    public int SEQNR { get; set; } = 1;

    /// <summary>Last changed on (AEDTM).</summary>
    public DateTime? AEDTM { get; set; }

    /// <summary>Changed by (UNAME).</summary>
    public string? UNAME { get; set; }

    /// <summary>Technical audit: record created date/time (UTC).</summary>
    public DateTime CreatedOn { get; set; }

    /// <summary>Technical audit: created by (user).</summary>
    public string? CreatedBy { get; set; }

    /// <summary>Technical audit: record last updated date/time (UTC); null until first update.</summary>
    public DateTime? ChangedOn { get; set; }

    /// <summary>Technical audit: last changed by (user).</summary>
    public string? ChangedBy { get; set; }
}
