# Table Maker: Open Design Questions

## API Design Decisions

### Q3: Welfare Type Selection
**Status**: 🔴 **DECISION REQUIRED**

**Scenario**: COL 2010 has both income (INC) and consumption (CON) data available.

**Question**: Who selects welfare type?

**Options**:
- **User-Selected**: API request includes `"welfare_type": "income"` or `"consumption"`
  - Allows users to compare across types
  - Requires API parameter
  
- **Survey-Specific**: Each survey has a default; user cannot override
  - Simpler; less flexible

**Recommendation**: **User-selected**. Users may want to compare income vs. consumption welfare measures.

**Decision Needed**: Confirmation + API schema design


---

### Q5: Multiple Poverty Lines Format
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Scenario**: User requests `poverty_headcount` with `"poverty_lines": [1.9, 3.2]`.

**Question**: How should results be formatted?

**Options**:
- **Separate Rows (RECOMMENDED)**: Each poverty line gets its own row
  ```
  [
    { measure: "poverty_headcount", poverty_line: 1.9, value: 0.154 },
    { measure: "poverty_headcount", poverty_line: 3.2, value: 0.234 }
  ]
  ```
  - Easier for UI; matches request structure
  
- **Separate Columns**: All poverty lines in one row as different columns
  - Wider table; less flexible

**Recommendation**: **Separate rows** (long format).

**Decision Needed**: Confirmation + response schema finalization

---

### Q6: Subgroup Totals (All/Summary Rows)
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Scenario**: User requests breakdown by gender. Should output include an "all genders" aggregate?

**Example**:
```
Without totals:
| country | year | gender | value |
| COL     | 2010 | male   | 0.15  |
| COL     | 2010 | female | 0.18  |

With totals:
| country | year | gender | value |
| COL     | 2010 | male   | 0.15  |
| COL     | 2010 | female | 0.18  |
| COL     | 2010 | all    | 0.165 |
```

**Options**:
- **Always Include**: Provides summary without separate query
- **Optional**: User controls via `"include_totals": true/false` parameter
- **Skip**: UI computes aggregate if needed

**Recommendation**: **Always include by default**. Allows UI to display overall statistics.

**Decision Needed**: Confirmation + API parameter name

---

## Computation Engine Decisions


### Q9: Memory Management for Large Datasets
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Questions**:
- What is the server's actual memory limit?
- Should we implement safeguards (e.g., "if total microdata > X MB, return error")?
- Should large queries be queued/async instead of immediate?

**Recommended Actions**:
- Benchmark typical query memory usage in Phase 2.5
- Set max query size at ~80% of available memory
- Return 400 error if user exceeds threshold
- Consider async execution for very large queries (>30 sec)

**Decision Needed**:
- Memory limit threshold?
- Error handling strategy?
- Async execution policy?

---

### Q10: Edge Case: Empty Groups / Zero Observations
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Scenario**: After filtering/grouping, a combination has zero observations.
- Example: Women age 0-5 in a particular survey (n=0)

**Question**: How should system respond?

**Options**:
- **Return Null/NA**: Value = null, n=0
- **Return Zero**: Value = 0, n=0
- **Omit Row**: Skip in output entirely
- **Return Percentage (0)**: For rates, return 0%; for counts, return 0

**Decision Needed**: What's the preferred behavior for empty groups?

---

## Scaling & Performance

### Q11: Synchronous vs. Asynchronous Execution
**Status**: 🟡 **STAKEHOLDER & ENGINEERING INPUT REQUIRED**

**Question**: How long should users wait for results?

**Scenarios**:
- Typical query (3 surveys): **<2 seconds** → User can wait
- Large query (15 surveys): **<30 seconds** → User patience limit
- Very large query (15 surveys + 15 measures + 3 breakdowns): **>60 seconds** → User timeout risk

**Options**:
- **Always Synchronous**: Block until complete
  - Simple implementation
  - Risk: User timeout if query slow
  
- **Always Asynchronous**: Return 202 "Accepted" + job ID; user polls
  - Better for long queries
  - More complex; worse UX for fast queries
  
- **Hybrid (RECOMMENDED)**: Sync with timeout
  - <15 sec: Synchronous response
  - >15 sec: Return 202 + job ID
  - Best UX; most complex

**Recommendation**: **Start with always synchronous + 60-sec timeout**. Upgrade to async if performance testing shows bottlenecks.

**Decision Needed**: Which approach? What timeout value?

---

### Q12: Caching Strategy
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Question**: Should identical queries be cached to avoid re-computation?

**Scenario**:
- User 1: "COL_2010, poverty_headcount, by gender" → computed
- User 2 (1 hour later): Same request → should we return cached result?

**Trade-off: Performance vs. Freshness**

**Options**:
- **No Caching**: Always fresh; repeated queries re-computed (wastes CPU)
- **Time-Based Cache (TTL)**: Cache expires after X hours
  - 1-hour TTL: Moderate staleness risk
  - 24-hour TTL: Higher staleness risk; better performance
  
- **Smart Cache (RECOMMENDED)**: Cache with intelligent invalidation
  - Cache all results
  - Clear cache at PIP data releases (when Arrow updates)
  - Result: Fresh data + repeated query performance
  - Implementation: Cache expires on PIP Spring/Fall release dates

**Recommendation**: **Smart cache with PIP release invalidation**.

**Decision Needed**: 
- Cache TTL before release dates?
- Cache key format (request hash vs. parameters)?
- Monitoring/metrics for cache hit rates?

---

## Authentication & Rate Limiting

### Q13: Authentication & Access Control
**Status**: 🔴 **IT & PRODUCT DECISION REQUIRED**

**Questions**:
- Is API public or authenticated?
  - **Public**: Anyone can query (no API key)
  - **Authenticated**: API key required
  - **Hybrid**: Public for limited requests; authenticated for unlimited
  
- Are there rate limits?
  - Example: 10 requests/minute per IP address
  - Helps prevent abuse

**Recommendation**:
- **MVP**: Start public (no auth) with light rate limiting
- **Later**: Add authentication if abuse detected or if moved to restricted access

**Decision Needed**: MVP authentication policy? Rate limit thresholds?

---

### Q14: Rate Limiting Details
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Question**: What rate limits should be enforced?

**Options**:
- **Per IP Address**: 10-20 requests/minute
- **Per User (if authenticated)**: 100+ requests/minute
- **Per Query Type**: Stricter limits on expensive queries
- **No Limits**: Trust user behavior

**Recommendation**: Start with **10 requests/minute per IP** for public API.

**Decision Needed**: Rate limit values? Enforcement method? Error responses?

---


---

### Q17: Export Formats Beyond JSON
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Question**: What export formats should API support?

**Options**:
- **JSON** (required) ✓
- **CSV** (nice-to-have)
- **Excel** (nice-to-have)
- **Other** (Stata, R, etc.)

**Recommendation**: MVP = JSON only. Add CSV/Excel in Phase 2 if requested.

**Decision Needed**: Supported formats? Priority order?

---

### Q18: API Pagination
**Status**: 🟡 **CLARIFICATION REQUIRED**

**Question**: Should API paginate large result sets?

**Scenario**: Result set has 1000+ rows.

**Options**:
- **Always Return All**: No pagination; client handles large responses
  - Simple; risk: slow for very large results
  
- **Paginate by Default**: Return page 1 (e.g., 100 rows); client requests next pages
  - Responsive; more complex

**Recommendation**: **Return all results** for MVP. Pagination if response size becomes limiting.

**Decision Needed**: Pagination approach? Page size?

---

## Data Quality & Testing

### Q19: Input Validation Edge Cases
**Status**: 🟡 **SPECIFICATION REQUIRED**

**Unresolved Validation Rules**:

1. **Survey Validity**: 
   - What constitutes a valid survey?
   - How to check availability in Arrow dataset?

2. **Measure Validity**:
   - Which measures are supported?
   - How to validate poverty_lines (numeric, >0, reasonable range)?

3. **Breakdown Validity**:
   - Max dimensions = 3 (enforce limit?)
   - Which dimensions are always available vs. survey-specific?

4. **Welfare Variable**:
   - Should API support both "welfare_ppp" and "welfare_lcu"?
   - How to determine which is available per survey?

**Decision Needed**: Detailed validation rules and error messages?

---

### Q20: Testing & Benchmarking
**Status**: 🔴 **PHASE 2.5 TASK**

**Needed**:
- Benchmark actual query latencies (typical, medium, large)
- Profile memory usage per query type
- Load testing (concurrent users)
- Cache hit rates monitoring
- Error rate tracking

**Assigned to**: Technical team (Phase 2.5)

---

## Summary: Priority Decisions

### Immediate (Phase 1 Design):
- [ ] **Q8**: Measure computation approach (wrap {pipster} or implement new?)
- [ ] **Q3**: Welfare type selection (user vs. survey-specific)
- [ ] **Q7**: Missing variables handling (fail vs. skip)
- [ ] **Q11**: Sync vs. async execution (which approach?)

### Important (Before MVP Launch):
- [ ] **Q1**: Arrow generation trigger (on-demand vs. hybrid)
- [ ] **Q13**: Authentication & rate limiting policy
- [ ] **Q12**: Caching strategy (TTL vs. smart invalidation)
- [ ] **Q5, Q6**: Response format (multiple poverty lines, totals)

### Nice-to-Have (Phase 2):
- [ ] **Q16**: Standard errors & confidence intervals
- [ ] **Q17**: Export formats (CSV, Excel)
- [ ] **Q18**: API pagination
- [ ] **Q14**: Rate limit thresholds
