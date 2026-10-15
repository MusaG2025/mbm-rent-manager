/* MBM Rent Manager cloud backup and restore bridge.
   It deliberately keeps the existing app working offline and synchronises its
   three data sets to a private row in Supabase for the signed-in user. */
(function () {
  "use strict";

  const config = window.MBM_SUPABASE_CONFIG || {};
  const dataKeys = ["mbmTenantMaster", "mbmPropertyMaster", "mbmReceiptsContractFixed"];
  const statusEl = () => document.getElementById("cloudStatus");
  const byId = id => document.getElementById(id);
  let client = null;
  let session = null;
  let restoring = false;
  let saveTimer = null;

  function configured() {
    return /^https:\/\/.+\.supabase\.co\/?$/i.test(String(config.url || "")) &&
      String(config.anonKey || "").length > 20 &&
      !String(config.anonKey).includes("PASTE_");
  }

  function setStatus(message, type) {
    const el = statusEl();
    if (!el) return;
    el.textContent = message;
    el.className = "cloud-status" + (type ? " " + type : "");
  }

  function setButtons(signedIn) {
    ["cloudSaveBtn", "cloudLoadBtn", "cloudSignOutBtn"].forEach(id => byId(id)?.classList.toggle("hidden", !signedIn));
    ["cloudSignInBtn", "cloudSignUpBtn"].forEach(id => byId(id)?.classList.toggle("hidden", signedIn));
  }

  function jsonFromStorage(key, fallback) {
    try { return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback)); }
    catch (_) { return fallback; }
  }

  function localPayload() {
    return {
      tenant_master: jsonFromStorage("mbmTenantMaster", []),
      property_master: jsonFromStorage("mbmPropertyMaster", []),
      receipt_history: jsonFromStorage("mbmReceiptsContractFixed", [])
    };
  }

  function scheduleSave() {
    if (!client || !session || restoring) return;
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => saveNow(true), 900);
  }

  async function saveNow(quiet) {
    if (!client || !session) {
      if (!quiet) alert("Please sign in to your cloud database first.");
      return;
    }
    setStatus("Saving your latest changes to the private cloud database…", "connected");
    const row = Object.assign({ owner_id: session.user.id }, localPayload());
    const { error } = await client.from("mbm_app_state").upsert(row, { onConflict: "owner_id" });
    if (error) {
      console.error(error);
      setStatus("Cloud save did not finish: " + error.message, "error");
      if (!quiet) alert("The cloud save did not finish. Your data is still safe in this browser.\n\n" + error.message);
      return;
    }
    const email = session.user.email || "your account";
    setStatus("Saved securely for " + email + ".", "connected");
  }

  function refreshAppAfterLoad() {
    if (typeof ensureTenantPropertyLinks === "function") ensureTenantPropertyLinks();
    if (typeof rebuildPropertyDropdown === "function") rebuildPropertyDropdown();
    const reportProperty = byId("reportProperty");
    if (reportProperty && Array.isArray(properties)) {
      reportProperty.innerHTML = '<option value="">All Properties</option>';
      properties.filter(p => p.status !== "Archived").forEach(p => {
        const option = document.createElement("option");
        option.value = p.id;
        option.textContent = typeof propertyDisplayName === "function" ? propertyDisplayName(p) : p.erf || p.id;
        reportProperty.appendChild(option);
      });
    }
    if (typeof rebuildCustomerDropdowns === "function") rebuildCustomerDropdowns();
    if (typeof loadCustomer === "function" && byId("customer")?.options.length) loadCustomer();
    if (typeof renderHistory === "function") renderHistory();
    if (typeof runReport === "function") runReport();
  }

  async function loadCloudData() {
    if (!client || !session) return;
    const { data, error } = await client.from("mbm_app_state").select("tenant_master, property_master, receipt_history, updated_at").maybeSingle();
    if (error) {
      console.error(error);
      setStatus("Could not load cloud data: " + error.message, "error");
      return;
    }
    if (!data) {
      setStatus("No cloud backup exists yet. Use Save to Cloud to create your first backup.", "connected");
      return;
    }
    if (!confirm("Load the cloud backup and replace the data currently shown in this browser?\n\nOnly continue if this is the correct MBM account.")) return;
    restoring = true;
    try {
      localStorage.setItem("mbmTenantMaster", JSON.stringify(Array.isArray(data.tenant_master) ? data.tenant_master : []));
      localStorage.setItem("mbmPropertyMaster", JSON.stringify(Array.isArray(data.property_master) ? data.property_master : []));
      localStorage.setItem("mbmReceiptsContractFixed", JSON.stringify(Array.isArray(data.receipt_history) ? data.receipt_history : []));
      customers = jsonFromStorage("mbmTenantMaster", []);
      properties = jsonFromStorage("mbmPropertyMaster", []);
      refreshAppAfterLoad();
      setStatus("Cloud data loaded. Last backup: " + new Date(data.updated_at).toLocaleString() + ".", "connected");
    } finally {
      restoring = false;
    }
  }

  async function captureSession(nextSession) {
    session = nextSession;
    setButtons(Boolean(session));
    if (session) {
      setStatus("Signed in as " + (session.user.email || "your account") + ". Use Load Cloud Data or keep working and save.", "connected");
    } else {
      setStatus("Not signed in. Your information remains in this browser until you sign in.", "");
    }
  }

  async function signIn() {
    if (!client) return alert("First complete supabase-config.js using the setup guide.");
    const email = prompt("Enter your email address:");
    if (!email) return;
    const password = prompt("Enter your password:");
    if (!password) return;
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error) return alert("Sign-in failed: " + error.message);
    await captureSession(data.session);
  }

  async function signUp() {
    if (!client) return alert("First complete supabase-config.js using the setup guide.");
    const email = prompt("Choose an email address for the MBM owner account:");
    if (!email) return;
    const password = prompt("Choose a password with at least 8 characters:");
    if (!password) return;
    const { data, error } = await client.auth.signUp({ email, password });
    if (error) return alert("Account creation failed: " + error.message);
    if (!data.session) {
      alert("Your account was created. Check your email and confirm the account, then return here and sign in.");
      return;
    }
    await captureSession(data.session);
    alert("Account created. Click Save to Cloud to make the first private backup.");
  }

  async function signOut() {
    if (!client) return;
    await client.auth.signOut();
    await captureSession(null);
  }

  async function init() {
    if (!configured()) {
      setButtons(false);
      setStatus("Supabase is not configured yet. Follow the included setup guide first.", "");
      return;
    }
    if (!window.supabase?.createClient) {
      setStatus("The Supabase library did not load. Check your internet connection and reload the page.", "error");
      return;
    }
    client = window.supabase.createClient(config.url, config.anonKey);
    const originalSetItem = Storage.prototype.setItem;
    const originalRemoveItem = Storage.prototype.removeItem;
    Storage.prototype.setItem = function (key, value) {
      const result = originalSetItem.call(this, key, value);
      if (this === localStorage && dataKeys.includes(key)) scheduleSave();
      return result;
    };
    Storage.prototype.removeItem = function (key) {
      const result = originalRemoveItem.call(this, key);
      if (this === localStorage && dataKeys.includes(key)) scheduleSave();
      return result;
    };
    const { data } = await client.auth.getSession();
    await captureSession(data.session);
    client.auth.onAuthStateChange((_event, nextSession) => { captureSession(nextSession); });
  }

  window.MBMCloud = { init, signIn, signUp, signOut, saveNow, loadCloudData };
  init();
}());
