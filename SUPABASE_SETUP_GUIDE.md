# MBM Rent Manager — free Supabase setup

This version keeps working in the browser, but adds a secure online backup and restore database. It is intended for one MBM owner account first; every signed-in account can see only its own data.

## What you need

- A free Supabase account: https://supabase.com/
- An email address you can access
- A free static host for the web app, such as GitHub Pages. Opening `index.html` directly from a folder is fine for trying the offline app, but hosting it is more reliable for login and cloud access.

## 1. Create the free Supabase project

1. Go to https://supabase.com/dashboard and create an account.
2. Create a **new project** and choose the **Free** plan.
3. Give it a name such as `mbm-rent-manager`, choose a strong database password, and wait for it to finish creating.
4. Open **SQL Editor**, choose **New query**, paste everything from `supabase-schema.sql`, and press **Run**. You should see a success message.

The database is protected by Row Level Security. That means an authenticated user can read or change only the row that belongs to their own account.

## 2. Get the two browser-safe connection values

1. In the project, open **Project Settings → API**.
2. Copy the **Project URL**.
3. Copy the **anon public** key (sometimes labelled `Publishable key`).
4. Open `supabase-config.js` in this app folder and paste the two values between the quotation marks.

Never paste the `service_role` key into this file or into a website. It bypasses the database security rules.

## 3. Create your MBM login and make the first backup

1. Put the updated app folder on a web host (see section 4) and open the website.
2. Select **Create Account** in the Secure cloud database bar.
3. Use the email address that will own the MBM rent records. Supabase may ask you to confirm your email; do that, then use **Sign In**.
4. Select **Save to Cloud**. This copies the existing properties, tenant master and receipt history to your private cloud database.
5. On another device, use the same hosted link, sign in with the same email, then select **Load Cloud Data**.

The app automatically saves again shortly after you add or edit a property, tenant or receipt. The **Save to Cloud** button lets you save immediately.

## 4. Publish free with GitHub Pages

1. Create a free GitHub account at https://github.com/.
2. Create a new repository named `mbm-rent-manager` and select **Public**.
3. Upload the *contents* of this folder, including `index.html`, `supabase-config.js`, `supabase-cloud.js`, `supabase-schema.sql`, `manifest.webmanifest` and `service-worker.js`.
4. In the repository, open **Settings → Pages**. Under *Build and deployment*, select **Deploy from a branch**, choose `main` and `/ (root)`, then save.
5. Wait a few minutes. GitHub will show the web address for your app.

Do not upload a real service-role key, bank exports, passwords or other private files to a public GitHub repository. The Supabase anon/publishable key is normal to use in a web app because the database policies protect the records.

## WhatsApp Business: the free option included

The green **Send Receipt via WhatsApp** button is intentionally a free Click-to-Chat link. It opens a WhatsApp/WhatsApp Business conversation with the tenant's phone number and fills in the receipt message; you check it and tap **Send** yourself.

This works with the free WhatsApp Business mobile app and does not require an API, a Meta developer account or a paid messaging provider. It is the right starting point for MBM.

An automated system that sends WhatsApp messages itself is different: it needs the official WhatsApp Business Platform, Meta account setup, approved templates and can charge per message. Do not use unofficial tools that automate the WhatsApp Web session—they can put the business number at risk.

## What the free plan is suitable for

For a small rental manager, Supabase's free plan is suitable for learning and a small live app. Keep a monthly exported CSV/PDF backup as well. Free plans and messaging pricing can change, so check the providers' current limits before relying on them for a larger business.
