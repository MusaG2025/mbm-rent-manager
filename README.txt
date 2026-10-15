MBM Rent Manager - Website Application Upgrade

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

WHATSAPP BUSINESS
-----------------
- The Send Receipt button uses free WhatsApp Click-to-Chat with a pre-filled
  receipt message. Open it using the WhatsApp Business app and press Send.
- Fully automatic WhatsApp API sending is not included because it requires
  Meta platform configuration and may have message charges.


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
