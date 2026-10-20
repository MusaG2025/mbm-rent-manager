# MBM Property Manager V10

**Your Trusted Property Partner**  
Managing Properties. Building Value.  
Musa Business Management CC · Property & Rental Management · 081 424 4350

## What V10 delivers

V10 consolidates the usable V1–V9 MBM workflows into one property-management workspace. It is designed around the same practical operating model as leading systems such as Rent Manager: portfolio and vacancies → people and leasing → receivables → maintenance and suppliers → documents, communications and reporting.

One shared workspace now connects:

- Property, unit, owner, prospect and vacancy master data
- Tenants, leases, contracts, deposit records, documents and live expiry dates
- A controlled renewal process: notice, negotiation, legal review, management approval, signature and billing activation
- Charges, payments, payment allocations, printable receipts, WhatsApp Click-to-Chat and historical receipt imports
- One municipal account per property plus municipal payment history and CSV export
- Suppliers, quoted vs actual maintenance cost, work orders, inspections, defects and follow-up controls
- A unified calendar, manual property events and standard `.ics` calendar export
- Compliance, document-control, vacancy, finance, lease, municipal and operations reports with CSV exports
- Role design and audit records ready for Supabase Row Level Security

## What was retained from V1–V9

- Property / ERF master, tenant and contract records
- Receipt creation, printing, reprinting and free WhatsApp receipt messages
- Historic-payment CSV/JSON import
- Contract expiry countdown and the renewal approval gate
- Municipal balance tracker and future API-ready account mapping
- Maintenance, inspections, calendar and compliance workflow
- Browser backup/import and migration from the previous MBM browser keys

Nothing from the old releases should be deleted until the V10 migration has been tested against real data and a backup has been downloaded.

## First local test

Open `index.html` in a browser. On first use it detects the older MBM browser data and creates a V10 copy of available properties, tenants, leases, receipts, municipal accounts, renewals, operations and calendar events. The old data is not deleted.

Use **Administration → Download full backup** before and after testing. Then test in this order: Property → Unit → Owner/prospect (if needed) → Lease → Charge → Payment → Renewal → Work order → Inspection → Report.

## Supabase setup

1. In Supabase open **SQL Editor → New query**.
2. Paste all of `supabase-v1-schema.sql` and select **Run**.
3. Configure authentication and Redirect URLs for the future hosted application.
4. Do not publish a service-role key in GitHub Pages or any browser file.

The V10 screen is a working browser workspace with backup/import and V1–V9 migration. The supplied schema is the relational cloud foundation. Before inviting staff or exposing an external data API, wire the screens to the organisation-scoped Supabase tables and test the Row Level Security policies.

## Safe future integrations

- **Municipality:** use a Supabase Edge Function and a municipality-approved API; never put municipality credentials in GitHub Pages.
- **WhatsApp:** the current Click-to-Chat approach is free and requires staff review before sending. WhatsApp Cloud API automation is a later paid/approved integration.
- **External reporting / owner portal:** expose a read-only Supabase view or authenticated Edge Function after access rules are defined.

## Publish on GitHub Pages

Upload the files in this folder to the root of a new or dedicated GitHub repository. In **Settings → Pages**, select `main` and `/(root)`.
