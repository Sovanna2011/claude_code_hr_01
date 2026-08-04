using HRModule.Api.Data;
using HRModule.Api.DTOs;
using HRModule.Api.Models.Infotypes;
using HRModule.Api.Models.Modules;
using HRModule.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HRModule.Api.Services;

/// <summary>
/// Leave-management service. Requests move Pending → Approved/Rejected. Approving
/// a request records the absence (IT2001) and deducts the matching absence quota
/// (IT2006) in a single transaction, reproducing the SAP leave → quota link.
/// </summary>
public class LeaveService : ILeaveService
{
    private readonly HRDbContext _db;
    public LeaveService(HRDbContext db) => _db = db;

    public async Task<IReadOnlyList<LeaveRequestDto>> GetRequestsAsync(int? pernr, CancellationToken ct = default)
    {
        var query = _db.Set<LeaveRequest>().AsNoTracking();
        if (pernr is not null) query = query.Where(r => r.PERNR == pernr);

        var rows = await query.OrderByDescending(r => r.RequestedOn).ToListAsync(ct);
        if (rows.Count == 0) return new List<LeaveRequestDto>();

        // Resolve leave-type texts (T554S) and employee names (IT0002 valid today).
        var typeTexts = await _db.T554S.AsNoTracking()
            .ToDictionaryAsync(t => t.AWART, t => t.ATEXT, ct);

        var today = DateTime.Today;
        var pernrs = rows.Select(r => r.PERNR).Distinct().ToList();
        var names = await _db.PA0002.AsNoTracking()
            .Where(p => pernrs.Contains(p.PERNR) && p.BEGDA <= today && p.ENDDA >= today)
            .Select(p => new { p.PERNR, p.VORNA, p.NACHN })
            .ToListAsync(ct);
        var nameMap = names.ToDictionary(n => n.PERNR, n => $"{n.VORNA} {n.NACHN}".Trim());

        return rows.Select(r => new LeaveRequestDto
        {
            RequestId = r.RequestId,
            Pernr = r.PERNR,
            EmployeeName = nameMap.GetValueOrDefault(r.PERNR),
            LeaveTypeKey = r.AWART,
            LeaveType = typeTexts.GetValueOrDefault(r.AWART),
            Begda = r.BEGDA, Endda = r.ENDDA, Days = r.Days,
            Status = r.Status, Note = r.Note,
            RequestedOn = r.RequestedOn, DecidedBy = r.DecidedBy, DecidedOn = r.DecidedOn
        }).ToList();
    }

    public async Task<LeaveRequestDto> CreateRequestAsync(int pernr, CreateLeaveRequest r, CancellationToken ct = default)
    {
        if (!await _db.Employees.AnyAsync(e => e.PERNR == pernr, ct))
            throw new ArgumentException($"Employee {pernr} not found.");
        if (r.Endda < r.Begda)
            throw new ArgumentException("End date must not be before start date.");

        var days = r.Days ?? (decimal)((r.Endda - r.Begda).Days + 1);

        var entity = new LeaveRequest
        {
            PERNR = pernr, AWART = r.LeaveType,
            BEGDA = r.Begda, ENDDA = r.Endda, Days = days,
            Status = "Pending", Note = r.Note, RequestedOn = DateTime.Now
        };
        _db.Add(entity);
        await _db.SaveChangesAsync(ct);

        var typeText = await _db.T554S.AsNoTracking()
            .Where(t => t.AWART == r.LeaveType).Select(t => t.ATEXT).FirstOrDefaultAsync(ct);
        var today = DateTime.Today;
        var name = await _db.PA0002.AsNoTracking()
            .Where(p => p.PERNR == pernr && p.BEGDA <= today && p.ENDDA >= today)
            .Select(p => p.VORNA + " " + p.NACHN).FirstOrDefaultAsync(ct);

        return new LeaveRequestDto
        {
            RequestId = entity.RequestId, Pernr = pernr, EmployeeName = name?.Trim(),
            LeaveTypeKey = entity.AWART, LeaveType = typeText,
            Begda = entity.BEGDA, Endda = entity.ENDDA, Days = entity.Days,
            Status = entity.Status, Note = entity.Note, RequestedOn = entity.RequestedOn
        };
    }

    public async Task<bool> DecideAsync(int requestId, LeaveDecisionRequest r, CancellationToken ct = default)
    {
        var req = await _db.Set<LeaveRequest>().FirstOrDefaultAsync(x => x.RequestId == requestId, ct);
        if (req is null) return false;
        if (!string.Equals(req.Status, "Pending", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException($"Request {requestId} has already been {req.Status.ToLowerInvariant()}.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        if (r.Approve)
        {
            // Deduct from a matching quota valid over the absence start date.
            var quota = await _db.PA2006
                .Where(q => q.PERNR == req.PERNR && q.KTART == req.AWART
                            && q.BEGDA <= req.BEGDA && q.ENDDA >= req.BEGDA)
                .OrderByDescending(q => q.BEGDA).FirstOrDefaultAsync(ct);
            if (quota is not null)
            {
                if (quota.ANZHL - quota.KVERB < req.Days)
                    throw new InvalidOperationException("Insufficient leave quota to approve this request.");
                quota.KVERB += req.Days;
                quota.AEDTM = DateTime.Today;
                quota.UNAME = r.DecidedBy;
            }

            _db.PA2001.Add(new PA2001
            {
                PERNR = req.PERNR, SUBTY = req.AWART, AWART = req.AWART,
                BEGDA = req.BEGDA, ENDDA = req.ENDDA, ABWTG = req.Days,
                APPROVED = true, AEDTM = DateTime.Today, UNAME = r.DecidedBy
            });

            req.Status = "Approved";
        }
        else
        {
            req.Status = "Rejected";
        }

        req.DecidedBy = r.DecidedBy;
        req.DecidedOn = DateTime.Now;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return true;
    }
}
