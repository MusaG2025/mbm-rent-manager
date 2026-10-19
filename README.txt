MBM Rent Manager - Website Application Upgrade

CORPORATE PROPERTY MANAGEMENT SYSTEM INTERFACE
------------------------------------
The application is organised around a corporate property and landlord-revenue lifecycle:
- Corporate Dashboard — portfolio, revenue and control exposure snapshot
- Portfolio & Assets — ERF/property inventory, status and occupancy baseline
- Leasing & Contracts — tenant, unit, rent, contact, agreement reference, signed status and contract register
- Renewals & Lease Pipeline — expiry review, formal notice, term negotiation, legal review, management approval, signature and billing activation
- Operations Calendar — live calendar for expiry, renewal actions, inspections, work-order deadlines and manual property events
- Municipal Bill — one property-linked municipal account and current balance
- Maintenance & Work Orders — create, assign, prioritise and close property repairs
- Inspections & Unit Turns — schedule and complete property, safety and move-in/move-out inspections
- Billing & Receipts — detailed payment capture, receipt issue and WhatsApp delivery
- Collections History — historical payments, imports and reprints
- Compliance & Assurance — missing contract, renewal and municipal exceptions
- Corporate Reports — collection, arrears, deductions and CSV/PDF reporting
- System & Integrations — architecture overview, cloud backup and future API readiness

The corporate design was aligned to the EPLA Property & Real Estate lifecycle:
portfolio baseline; vacancy and revenue exposure; renewal eligibility; lease preparation;
lease execution; billing and compliance monitoring; closure; and independent assurance.

The existing tenant master, property master, receipt history, Supabase cloud backup and WhatsApp Click-to-Chat functions remain in place.

CONTRACT RENEWAL WORKFLOW
-------------------------
- Each tenant/unit contract records a reference number, start date, issue state, agreement status, expiry date and renewal follow-up date.
- The Contract Register displays a live days-to-expiry countdown and highlights contracts within the 90-day renewal window.
- Start a Renewal Case to move the lease through: Expiry Review → Notice Issued → Terms Negotiation → Legal Review → Management Approval → Awaiting Signature → Renewed / Billing Activated (or Non-renewal / Exit).
- A renewal cannot be activated unless Legal Review is Approved by legal, Management Approval is Approved, and a signed agreement reference, signature date, billing activation date, term and rent have been entered.
- When activated, the system updates the live tenant lease with the new agreement reference, renewal start/end date and agreed rent.
- Use WhatsApp update to open a free pre-filled renewal message for the tenant. The user must review and press Send in WhatsApp Business.
- When signed in, PDFs, Word files and contract images can be uploaded to the private Supabase document vault and opened through a short-lived secure link. Offline use still records the filename until it can be uploaded.

OPERATIONS CALENDAR
-------------------
- Contract expiry, renewal next actions, inspection schedules, open work-order due dates and unpaid municipal due dates appear automatically.
- Add manual management meetings, vendor appointments, viewings and other portfolio events.
- Export the selected month as a standard .ics calendar file for no-cost import into Outlook or Google Calendar.

MUNICIPAL BILL
--------------
- Add one latest municipal statement balance per property.
- Store the municipal account number, statement date, due date and notes.
- See the total municipal amount owing on the Dashboard.
- Record a municipal payment to reduce the current balance, or update it when the next statement arrives.
- The module is API-ready: its property link and municipal account number can be mapped to a future approved municipality API.
- It starts as a manual tracker. Automatic bill retrieval or payment can be added only after the municipality provides authorised API access and credentials.

NEW: Upload / Import Previous Payments

You can now upload already-made historical payments and have them populate:
- Saved Receipt History
- Rental Income Reporting

Accepted:
- CSV
- JSON

Built-in controls:
- Download CSV template
- Preview before import
- Validate tenant, unit, month, year and amount
- Skip duplicate receipt numbers
- Optional Update mode for matching receipt numbers
- Automatic reporting refresh after import
- Existing saved receipts remain protected unless Update mode is selected

Recommended CSV columns:
receipt_no
receipt_date
month
year
tenant
contact
unit
amount
pending
deductions
payment_method
contract_issued
notes

If receipt_no is blank, the application creates one automatically.

All existing MBM features remain in the application.


SUPABASE CLOUD DATABASE UPGRADE
-------------------------------
- The app now supports a secure, private Supabase cloud database while keeping
  the existing offline browser copy working.
- Follow SUPABASE_SETUP_GUIDE.md from start to finish.
- Run supabase-schema.sql once in your Supabase SQL Editor.
- Paste only the Project URL and anon/publishable key in supabase-config.js.
- Never use a Supabase service_role key in this website.
- The database is private per signed-in user through Row Level Security.
- Existing tenant, property and receipt records are saved/restored together.
- Municipal account records are saved/restored together with the other private MBM data.
- Work orders and inspection records are saved/restored together with the other private MBM data.
- Renewal cases and manual calendar events are saved/restored with the other private MBM data.

WHATSAPP BUSINESS
-----------------
- The Send Receipt button uses free WhatsApp Click-to-Chat with a pre-filled
  receipt message. Open it using the WhatsApp Business app and press Send.
- Fully automatic WhatsApp API sending is not included because it requires
  Meta platform configuration and may have message charges.
- Contract renewal updates use the same free Click-to-Chat approach: the message opens ready to review and send.


NEW PROPERTY / ERF MASTER UPGRADE
---------------------------------
- Added + New Property / ERF... inside the Property selector.
- Added Edit Property.
- Property popup captures:
  ERF Number
  Property Name
  Street Address
  Suburb
  Town / City
  Property Type
  Status
  Notes
- ERF 3478 Khomasdal - Shanghai Street remains the existing seeded property.
- Existing historical receipts remain linked to ERF 3478 by default.
- New properties are saved in browser storage.
- New/edit client workflow can link tenants/units to a selected property where supported.
- Reporting can filter by property.
- Existing receipt, WhatsApp, import previous payments, deduction calculation, contracts, history and reporting features remain.
