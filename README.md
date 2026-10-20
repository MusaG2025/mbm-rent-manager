# MBM Property Management — V12

This is the MBM operational workspace for property, leases, renewals, receipts, municipal accounts, maintenance, inspections, documents, compliance and reporting. It is deliberately split into two deployable parts:

| Part | Purpose | Deploy to |
| --- | --- | --- |
| Website files in this folder | The MBM user interface; works in browser-local mode and supports the existing Supabase cloud backup | GitHub Pages |
| `backend/` | Java / Spring Boot API and PostgreSQL migrations for the long-term, multi-user system | A Java-capable web-service host |

## Start with the website

1. Open `supabase-config.js` and confirm the Project URL and **publishable** key are present. Never put a database password, service-role key or secret key in this file.
2. Create a GitHub repository, for example `mbm-property-manager`.
3. Upload only these website files to the repository root: `index.html`, `app.css`, `app.js`, `supabase-config.js`, `supabase-cloud-v10.js`, and `supabase-v12-schema.sql`. Do **not** upload the `backend` folder to the Pages repository.
4. In GitHub: **Settings → Pages → Deploy from a branch → main → /(root) → Save**.
5. Wait for the Pages deployment notice, then open the URL shown there. It is normally `https://YOUR-GITHUB-USERNAME.github.io/REPOSITORY-NAME/`.
6. Use **Settings & Security → Create Account / Sign in**, then use **Save to Cloud**. The app will preserve browser data and can restore it on another device with **Load Cloud Data**.

The browser interface is immediately usable. The Java API is prepared for the next stage, when records must be shared and stored as real relational data instead of browser-backed workspace data.

## Smart features included

- Search across properties, units, tenants, agreements, municipal accounts and work orders.
- Property hierarchy: portfolio → region → property → building → floor → unit.
- Location suggestions using OpenStreetMap search, plus device location when you choose it.
- Property 360 view, agreement renewal countdowns, termination control, occupancy, receipting and WhatsApp receipt links.
- Municipal account and meter reading tracking; the future integration point is already modelled without pretending a municipality API exists today.
- Maintenance, inspections, documents, compliance, tasks and connected reporting.

## Important security rule

The publishable key is safe to use in the public website. A service-role key, database password and API-host environment values are never safe to publish or commit to GitHub. Keep them only in the secure Environment/Secrets area of the Java hosting service.

## Next stage

Follow [`backend/README.md`](backend/README.md) to deploy the Java API. The current front end intentionally continues to use the browser/Supabase backup workflow until the API connection is enabled module by module. This avoids moving live operational data to an unfinished API.
