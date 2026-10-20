# MBM V11 — connected property-management architecture

## Design decision

MBM is one property-management workspace. A property is created once and becomes the parent record for all operational information. The system must never require users to recreate the address in billing, municipal accounts, service work, documents or reporting.

## Operating model

```text
Property → Unit → Agreement / Occupancy → Charges & Receipts
   ├→ Municipal account
   ├→ Work orders & inspections
   ├→ Documents & compliance
   └→ Calendar, control queue & reports
```

## Main workspaces

| Workspace | Purpose | Records it uses |
|---|---|---|
| Today | One action queue for the manager | Exceptions, upcoming dates, KPI totals |
| Properties | Property 360° master record | Properties, location, units, linked summaries |
| Occupancy | One resident/agreement lifecycle | Prospects, tenants, leases, renewals, vacancies |
| Money | Receivable and operating-cost control | Charges, allocations, receipts, municipal accounts |
| Service Centre | Property service delivery | Suppliers, work orders, inspections, costs |
| Control Centre | Governance and deadlines | Calendar, renewals, documents, tasks, compliance exceptions |
| Insights | Flexible management reporting | Live connected data, report scope, CSV export |

## Core integrity rules

1. A unit must belong to one property.
2. An agreement uses an existing property and unit.
3. A charge and receipt use an agreement; the agreement identifies the property.
4. A municipal account, work order, inspection and document select an existing property.
5. Contract expiry, renewal actions, municipal due dates, work-order due dates, inspection dates and tasks create the Control Centre timeline.
6. Reports calculate from these records; reports do not store a second copy of the numbers.

## Smart entry

- Property address suggestions use the free OpenStreetMap/Nominatim service after three typed characters.
- “Use my location” uses the browser’s permission-based location feature and reverse-geocodes the coordinates when available.
- Unit options are filtered after selecting a property in forms that use both fields.
- Controlled dropdowns are used for property type, unit status, agreement status, charge type, payment method, service priority, inspection type and document status.

## Free Smart Assistant

MBM Smart Assistant is intentionally local and zero-cost. It can answer operational questions from the records in the browser, including arrears, municipal balance, expiring contracts, maintenance, vacancies and priorities. It does not send the portfolio data to an external AI service.

A true generative-AI assistant would require either a paid API or a locally hosted model and must be added only after a data-privacy decision, access controls and a budget are approved.

## Integration boundary

The current municipal register is one controlled account per property. A future municipal API must use the property ID and municipal account number; it should update statement/balance data without overwriting manually audited history. The Supabase schema remains the foundation for organisation-scoped staff access, private documents and future APIs.
