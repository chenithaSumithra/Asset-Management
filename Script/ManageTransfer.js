"use strict";

// ======================================================
// GLOBAL VARIABLES
// ======================================================

const pendingAssets = new Map();
const gridAssets = new Map();
const selectedAssets = new Set();
const lookupsInProgress = new Set();

let failedScans = 0;
let searchTimer = null;
let searchSequence = 0;
let saving = false;
let scanGeneration = 0;

// Keep scanned data after browser refresh.
const STORAGE_KEY =
    "AssetManagement.ManageTransfer.v1:" +
    window.location.pathname +
    window.location.search;

const el = id => document.getElementById(id);
const str = value => value == null ? "" : String(value);
const getValue = id => el(id) ? el(id).value : "";

// ======================================================
// BARCODE NORMALIZATION
// Example: 00020 becomes 20
// ======================================================

function normalizeNumericBarcode(value) {
    const text = str(value).trim();

    if (!/^\d+$/.test(text)) return null;

    const withoutZeros = text.replace(/^0+/, "");
    const number = Number(withoutZeros);

    return Number.isSafeInteger(number) &&
        number > 0 &&
        number <= 2147483647
        ? String(number)
        : null;
}

function extractBarcode(raw) {
    const input = str(raw).trim();

    if (!input) return null;

    const numeric = normalizeNumericBarcode(input);

    if (numeric) return numeric;

    try {
        const url = new URL(input);

        for (const key of [
            "barcodeId",
            "BarcodeId",
            "barcode",
            "Barcode",
            "id",
            "ID"
        ]) {
            const result = normalizeNumericBarcode(
                url.searchParams.get(key)
            );

            if (result) return result;
        }

        const segments = url.pathname
            .split("/")
            .filter(Boolean);

        return segments.length
            ? normalizeNumericBarcode(
                decodeURIComponent(
                    segments[segments.length - 1]
                )
            )
            : null;

    } catch (error) {
        return null;
    }
}

function validBarcode(value) {
    return extractBarcode(value) !== null;
}

// ======================================================
// ASP.NET WEBMETHOD REQUESTS
// ======================================================

function getWebMethodUrl(method) {
    return (
        window.manageTransferUrl ||
        window.location.pathname
    ).replace(/\/$/, "") + "/" + method;
}

async function callServer(method, payload) {
    const response = await fetch(
        getWebMethodUrl(method),
        {
            method: "POST",
            credentials: "same-origin",
            headers: {
                "Content-Type":
                    "application/json; charset=utf-8"
            },
            body: JSON.stringify(payload)
        }
    );

    if (!response.ok) {
        console.error(
            "WebMethod error:",
            method,
            response.status,
            await response.text()
        );

        throw new Error(
            "Server request failed (" +
            response.status + ")."
        );
    }

    const json = await response.json();

    if (!Object.prototype.hasOwnProperty.call(json, "d")) {
        throw new Error("Invalid WebMethod response.");
    }

    return json.d;
}

// ======================================================
// NOTIFICATIONS (status line + message line)
// ======================================================

function notify(message, error = false) {
    const messageElement = el("message");
    const statusElement = el("scannerStatus");
    const statusBox = document.querySelector(".scanner-status");

    if (messageElement) {
        messageElement.textContent = message;
        messageElement.style.color = error ? "#b42318" : "#087443";
    }

    if (statusElement) {
        statusElement.textContent = message;
    }

    // Red on error, otherwise the normal CSS (green) applies.
    if (statusBox) {
        statusBox.classList.toggle("status-error", error);
    }

    (error ? console.error : console.log)(message);
}

// ======================================================
// SWEETALERT HELPERS
// Supports SweetAlert2 (Swal.fire), SweetAlert 1 (swal),
// and falls back to a plain alert if neither is loaded.
// ======================================================

// Put the cursor back in the scanner box, unless a dialog is open.
function focusScanner() {
    const input = el("barcodeInput");

    if (!input) return;

    const transferOpen =
        el("checkoutModal") &&
        el("checkoutModal").classList.contains("visible");

    const conditionOpen =
        el("conditionModal") &&
        el("conditionModal").classList.contains("visible");

    if (!transferOpen && !conditionOpen) {
        input.focus();
    }
}

// Full popup. Used for every failure and for the transfer result.
/*function showAlert(title, message, icon, onClose) {
    const done = () => {
        if (typeof onClose === "function") onClose();
    };

    if (window.Swal && typeof window.Swal.fire === "function") {
        return window.Swal.fire({
            title: title,
            text: message,
            icon: icon,
            confirmButtonText: "OK"
        }).then(done);
    }

    if (typeof window.swal === "function") {
        window.swal(title, message, icon);
        done();
        return Promise.resolve();
    }

    window.alert(title + "\n\n" + message);
    done();
    return Promise.resolve();
}*/

// Small auto-closing SweetAlert. Used for successful scans so the
// scanner is not interrupted by a popup that needs a click.
/*function showToast(message, icon) {
    if (window.Swal && typeof window.Swal.fire === "function") {
        window.Swal.fire({
            toast: true,
            position: "top-end",
            icon: icon,
            title: message,
            showConfirmButton: false,
            timer: 2500,
            timerProgressBar: true,
            didOpen: focusScanner
        });
        return;
    }

    showAlert(
        icon === "success" ? "Success" : "Notice",
        message,
        icon,
        focusScanner
    );
}*/


// Popup for errors/warnings only. Anything else just updates the status line.
function showAlert(title, message, icon, onClose) {
    notify(message, icon === "error" || icon === "warning");
    if (typeof onClose === "function") onClose();
    return Promise.resolve();
}

function showToast(message, icon) {
    notify(message, icon === "error" || icon === "warning");
    focusScanner();
}
// ======================================================
// NORMALIZE ASSET DATA
// ======================================================


function normalizeAsset(asset, barcode) {
    return {
        BarcodeId: extractBarcode(
            asset.BarcodeId || barcode
        ) || str(barcode),

        AssetName: str(asset.AssetName),
        Serial: str(asset.Serial),
        MachineNo: str(asset.MachineNo),
        Model: str(asset.Model),
        Model_No: str(asset.Model_No),
        Status: str(asset.Status),
        StatusName: str(asset.StatusName),
        Condition: str(asset.Condition),

        Company: str(asset.Company),
        CurrentLocation : str(asset.CurrentLocation)
    };
}

// ======================================================
// SAVE TRANSFER STATE TO SESSION STORAGE
// ======================================================

function saveTransferState() {
    try {
        const empty =
            pendingAssets.size === 0 &&
            gridAssets.size === 0 &&
            failedScans === 0;

        if (empty) {
            window.sessionStorage.removeItem(STORAGE_KEY);
        } else {
            const state = {
                version: 1,
                pendingAssets: Array.from(pendingAssets.entries()),
                gridAssets: Array.from(gridAssets.entries()),
                selectedAssets: Array.from(selectedAssets),
                failedScans: failedScans
            };

            window.sessionStorage.setItem(
                STORAGE_KEY,
                JSON.stringify(state)
            );
        }

        return true;

    } catch (error) {
        console.warn(
            "Unable to save transfer batch:",
            error
        );

        return false;
    }
}

// ======================================================
// RESTORE TRANSFER STATE AFTER REFRESH
// ======================================================

function restoreTransferState() {
    try {
        const saved = window.sessionStorage.getItem(STORAGE_KEY);

        if (!saved) return;

        const state = JSON.parse(saved);

        if (!state || state.version !== 1) return;

        const restore = (items, target) => {
            if (!Array.isArray(items)) return;

            for (const pair of items) {
                if (
                    !Array.isArray(pair) ||
                    pair.length !== 2
                ) {
                    continue;
                }

                const id = extractBarcode(pair[0]);
                const asset = pair[1];

                if (
                    id &&
                    asset &&
                    typeof asset === "object" &&
                    !Array.isArray(asset)
                ) {
                    target.set(
                        id,
                        normalizeAsset(asset, id)
                    );
                }
            }
        };

        restore(state.gridAssets, gridAssets);
        restore(state.pendingAssets, pendingAssets);

        if (Array.isArray(state.selectedAssets)) {
            for (const raw of state.selectedAssets) {
                const id = extractBarcode(raw);

                if (id && gridAssets.has(id)) {
                    selectedAssets.add(id);
                }
            }
        }

        if (
            Number.isSafeInteger(state.failedScans) &&
            state.failedScans >= 0
        ) {
            failedScans = state.failedScans;
        }

    } catch (error) {
        console.warn(
            "Unable to restore transfer batch:",
            error
        );

        pendingAssets.clear();
        gridAssets.clear();
        selectedAssets.clear();
        failedScans = 0;

        try {
            window.sessionStorage.removeItem(STORAGE_KEY);
        } catch (storageError) {
            console.warn(storageError);
        }
    }
}

// ======================================================
// REFRESH PAGE AND RETAIN SCANNED ASSETS
// ======================================================

function refreshManageTransferPage() {
    if (saving) {
        notify(
            "A transfer is currently in progress.",
            true
        );
        return;
    }

    if (!saveTransferState()) {
        notify(
            "Unable to save this batch in browser storage. " +
            "Refreshing now would lose your scanned assets.",
            true
        );
        return;
    }

    window.location.assign(window.location.href);
}

// ======================================================
// RENDER COUNTERS AND FOOTER BUTTONS
// ======================================================

function renderCounts() {
    const total = pendingAssets.size + gridAssets.size;

    if (el("totalCount")) {
        el("totalCount").textContent = total;
    }

    if (el("selectedCount")) {
        el("selectedCount").textContent = selectedAssets.size;
    }

    if (el("footerSelectedCount")) {
        el("footerSelectedCount").textContent =
            selectedAssets.size;
    }

    if (el("errorCount")) {
        el("errorCount").textContent = failedScans;
    }

    if (el("batchBarcodes")) {
        el("batchBarcodes").value =
            Array.from(selectedAssets).join(", ");
    }

    // ==================================================
    // HIDE TRANSFER UNTIL ITEMS ENTER GRID
    // ==================================================

    const hasGridAssets = gridAssets.size > 0;

    for (const id of [
        "transferButton",
        "updateConditionButton"
    ]) {
        const button = el(id);

        if (button) {
            button.hidden = !hasGridAssets;

            button.style.display =
                hasGridAssets ? "" : "none";
        }
    }

    // ==================================================
    // SELECT ALL CHECKBOX STATE
    // ==================================================

    const selectAll = el("selectAllCheckbox");

    if (selectAll) {
        selectAll.checked =
            gridAssets.size > 0 &&
            selectedAssets.size === gridAssets.size;

        selectAll.indeterminate =
            selectedAssets.size > 0 &&
            selectedAssets.size < gridAssets.size;
    }

    saveTransferState();
}

// ======================================================
// RENDER PENDING ASSETS
// ======================================================

function renderPending() {
    const list = el("pendingAssetList");
    const panel = el("pendingStagingPanel");

    if (!list) return;

    const hasPendingAssets = pendingAssets.size > 0;

    if (panel) {
        panel.hidden = !hasPendingAssets;
    }

    list.hidden = !hasPendingAssets;

    list.replaceChildren();

    // Hide when no pending assets.
    list.hidden = pendingAssets.size === 0;
    list.style.removeProperty("display");

    // Show scanned assets only when available.
    for (const [id, asset] of pendingAssets) {
        const item = document.createElement("div");
        item.className = "pending-chip";

        const label = document.createElement("span");

        label.textContent =
            id + " - " + (asset.AssetName || "Asset");

        const remove = document.createElement("button");

        remove.type = "button";
        remove.className = "pending-remove";
        remove.textContent = "\u00d7";
        remove.title = "Remove barcode " + id;

        remove.addEventListener("click", () => {
            pendingAssets.delete(id);
            renderPending();
            notify("Removed pending asset " + id);
        });

        item.appendChild(label);
        item.appendChild(remove);

        list.appendChild(item);
    }

    if (el("pendingCount")) {
        el("pendingCount").textContent =
            "(" + pendingAssets.size + ")";
    }

    if (el("addItemsButton")) {
        el("addItemsButton").disabled =
            pendingAssets.size === 0;
    }

    renderCounts();
}

// ======================================================
// CLEAR TRANSFER PRECHECK ERRORS
// ======================================================

function clearTransferPrecheckFeedback() {
    const alert = el("transferPrecheckError");

    if (alert) {
        alert.textContent = "";
        alert.hidden = true;
    }

    const body = el("assetTableBody");

    if (body) {
        body.querySelectorAll(
            "tr.transfer-error-row"
        ).forEach(row => {
            row.classList.remove(
                "transfer-error-row"
            );
        });
    }
}

// ======================================================
// RENDER ASSET GRID
// ======================================================

function renderGrid() {
    const tbody = el("assetTableBody");

    if (!tbody) return;

    clearTransferPrecheckFeedback();
    tbody.replaceChildren();

    for (const [id, asset] of gridAssets) {
        const status = Number(
            str(asset.Status).trim()
        );

        const row = document.createElement("tr");

        row.dataset.barcodeId = id;

        // Checkbox
        const checkboxCell = document.createElement("td");
        const checkbox = document.createElement("input");

        checkbox.type = "checkbox";
        checkbox.checked = selectedAssets.has(id);

        checkbox.setAttribute(
            "aria-label",
            "Select barcode " + id
        );

        checkbox.addEventListener("change", () => {
            if (checkbox.checked) {
                selectedAssets.add(id);
            } else {
                selectedAssets.delete(id);
            }

            clearTransferPrecheckFeedback();
            renderCounts();
        });

        checkboxCell.appendChild(checkbox);
        row.appendChild(checkboxCell);

        // Asset details
        const values = [
            id,
            asset.AssetName,
            asset.Serial,
            asset.MachineNo,
            asset.Model,
            asset.Model_No,
            asset.Company,
            asset.CurrentLocation
        ];

        for (const value of values) {
            const td = document.createElement("td");

            td.textContent = str(value);

            row.appendChild(td);
        }

        // Colored status column
        const statusCell = document.createElement("td");

        statusCell.className =
            "asset-status-cell status-" + status;

        const badge = document.createElement("span");

        badge.className =
            "asset-status-badge status-" + status;

        badge.textContent =
            str(asset.StatusName).trim() ||
            (
                status > 0
                    ? "Status " + status
                    : "Unknown"
            );

        statusCell.appendChild(badge);
        row.appendChild(statusCell);

        // Condition column
        const conditionCell = document.createElement("td");

        conditionCell.textContent =
            str(asset.Condition);

        row.appendChild(conditionCell);

        // Remove action
        const actionCell = document.createElement("td");

        const remove = document.createElement("button");

        remove.type = "button";

        remove.className =
            "btn btn-danger asset-remove-button";

        remove.textContent = "Remove";

        // Preserve original Status 5 restriction.
        remove.disabled = status === 5;

        remove.title = remove.disabled
            ? "Remove is disabled for status 5."
            : "Remove barcode " + id;

        if (!remove.disabled) {
            remove.addEventListener("click", () => {
                gridAssets.delete(id);
                selectedAssets.delete(id);

                renderGrid();

                notify("Removed asset " + id);
            });
        }

        actionCell.appendChild(remove);
        row.appendChild(actionCell);

        tbody.appendChild(row);
    }

    if (el("emptyMessage")) {
        el("emptyMessage").style.display =
            gridAssets.size ? "none" : "";
    }

    renderCounts();
}

// ======================================================
// ADD ASSET TO PENDING LIST
// ======================================================

function addAssetToPending(asset, barcode) {
    const id = extractBarcode(
        barcode || asset.BarcodeId
    );

    if (!id) {
        notify("Invalid asset barcode.", true);
        return false;
    }

    if (
        pendingAssets.has(id) ||
        gridAssets.has(id)
    ) {
        notify(
            "Barcode " + id + " is already added.",
            true
        );
        return false;
    }

    pendingAssets.set(
        id,
        normalizeAsset(asset, id)
    );

    renderPending();

    notify(
        "Asset " + id +
        " loaded. Click Add Items."
    );

    return true;
}

// ======================================================
// QR SCANNER
// GetAssetByBarcode result:
//   Success  -> small SweetAlert toast (Message from server)
//   Failure  -> SweetAlert error popup (Message from server)
// ======================================================

async function stageBarcode(rawBarcode) {
    const id = extractBarcode(rawBarcode);

    // CHANGE 1: invalid QR
    if (!id) {
        failedScans++;
        renderCounts();

        showAlert(
            "Scan Failed",
            "Invalid QR code. A numeric barcode ID is required.",
            "error",
            focusScanner
        );

        return false;
    }

    // CHANGE 2: duplicate / already being scanned
    if (
        pendingAssets.has(id) ||
        gridAssets.has(id) ||
        lookupsInProgress.has(id)
    ) {
        showAlert(
            "Duplicate Scan",
            "Barcode " + id + " is already added or being scanned.",
            "error",
            focusScanner
        );

        return false;
    }

    lookupsInProgress.add(id);

    const generation = scanGeneration;

    try {
        const response = await callServer(
            "GetAssetByBarcode",
            { barcodeId: Number(id) }
        );

        if (generation !== scanGeneration) return false;

        if (!response || !response.Success || !response.Asset) {
            throw new Error(
                (response && response.Message) ||
                "No available asset found for barcode: " + id
            );
        }

        return addAssetToPending(response.Asset, id);

    } catch (error) {
        // CHANGE 3: asset not found / server error
        if (generation === scanGeneration) {
            failedScans++;
            renderCounts();

            showAlert(
                "Scan Failed",
                error.message || "Scan failed.",
                "error",
                focusScanner
            );
        }

        return false;

    } finally {
        lookupsInProgress.delete(id);
    }
}

// ======================================================
// HANDLE SCANNED QR INPUT
// ======================================================

async function handleAssetInput() {
    const input = el("barcodeInput");

    if (!input || !input.value.trim()) return;

    const raw = input.value.trim();
    const id = extractBarcode(raw);

    if (!id) {
        const message =
            "For text searches, select an asset from the search results.";

        notify(message, true);
        showAlert("Invalid Barcode", message, "warning", focusScanner);
        return;
    }

    clearTimeout(searchTimer);
    ++searchSequence;

    if (el("assetSearchResults")) {
        el("assetSearchResults").replaceChildren();
    }

    input.value = "";
    input.focus();

    await stageBarcode(id);

    if (
        document.activeElement === document.body ||
        document.activeElement === input
    ) {
        input.focus();
    }
}

// ======================================================
// SEARCH ASSETS
// SearchAssets result:
//   Success  -> results list (the server sends no message, and a
//               popup per keystroke would block typing)
//   Failure  -> SweetAlert toast (does not steal focus from the box)
// ======================================================

async function searchAssets(query) {
    const sequence = ++searchSequence;
    const container = el("assetSearchResults");

    if (!container) return;

    if (!str(query).trim()) {
        container.replaceChildren();
        return;
    }

    try {
        const response = await callServer(
            "SearchAssets",
            {
                search: str(query).trim()
            }
        );

        if (sequence !== searchSequence) return;

        container.replaceChildren();

        if (!response || !response.Success) {
            throw new Error(
                response && response.Message ||
                "Asset search failed."
            );
        }

        for (const asset of (response.Assets || [])) {
            const item = document.createElement("button");

            item.type = "button";
            item.className = "search-result-item";

            item.textContent = [
                asset.BarcodeId,
                asset.AssetName,
                asset.Serial,
                asset.Model
            ]
                .filter(Boolean)
                .join(" | ");

            item.addEventListener("click", () => {
                const id = extractBarcode(
                    asset.BarcodeId
                );

                if (!id) {
                    const message =
                        "Invalid barcode in search result.";

                    notify(message, true);
                    showAlert("Invalid Barcode", message, "error", focusScanner);
                    return;
                }

                clearTimeout(searchTimer);
                ++searchSequence;

                container.replaceChildren();

                el("barcodeInput").value = "";

                addAssetToPending(asset, id);

                el("barcodeInput").focus();
            });

            container.appendChild(item);
        }

        if (
            !response.Assets ||
            response.Assets.length === 0
        ) {
            container.textContent =
                "No matching assets.";
        }

    } catch (error) {
        if (sequence === searchSequence) {
            const message =
                error.message || "Search failed.";

            container.textContent = message;

            notify(message, true);
            showToast(message, "error");
        }
    }
}

// ======================================================
// ADD PENDING ITEMS INTO GRID
// ======================================================

function addItemsToGrid() {
    if (pendingAssets.size === 0) {
        notify(
            "No pending assets to add.",
            true
        );
        return;
    }

    const count = pendingAssets.size;

    for (const [id, asset] of pendingAssets) {
        if (!gridAssets.has(id)) {
            gridAssets.set(id, asset);

            // Auto-select only Status 1.
            if (Number(asset.Status) === 1) {
                selectedAssets.add(id);
            }
        }
    }

    pendingAssets.clear();

    renderPending();
    renderGrid();

    notify(
        count +
        " asset(s) added to the transfer grid."
    );

    if (el("barcodeInput")) {
        el("barcodeInput").focus();
    }
}

// ======================================================
// SELECT ALL / DESELECT ALL
// ======================================================

function toggleSelectAll(checked) {
    selectedAssets.clear();

    if (checked) {
        for (const id of gridAssets.keys()) {
            selectedAssets.add(id);
        }
    }

    renderGrid();
}

function selectAllAssets() {
    toggleSelectAll(true);
}

function deselectAllAssets() {
    toggleSelectAll(false);
}

// ======================================================
// CLEAR ALL SCANNED ASSETS
// ======================================================

function clearAllBarcodes() {
    scanGeneration++;

    pendingAssets.clear();
    gridAssets.clear();
    selectedAssets.clear();

    failedScans = 0;

    clearTimeout(searchTimer);
    ++searchSequence;

    if (el("assetSearchResults")) {
        el("assetSearchResults").replaceChildren();
    }

    if (el("barcodeInput")) {
        el("barcodeInput").value = "";
    }

    renderPending();
    renderGrid();

    notify("All assets cleared.");

    if (el("barcodeInput")) {
        el("barcodeInput").focus();
    }
}

// ======================================================
// INTERNAL / EXTERNAL TRANSFER SWITCH
// ======================================================

function changeCheckoutType() {
    const radio = document.querySelector(
        'input[name="checkoutType"]:checked'
    );

    if (!radio) return;

    const internal = radio.value === "Internal";

    el("internalSection").style.display =
        internal ? "" : "none";

    el("internalFields").style.display =
        internal ? "" : "none";

    el("externalSection").style.display =
        internal ? "none" : "";

    el("externalFields").style.display =
        internal ? "none" : "";

    el("internalCard").classList.toggle(
        "active",
        internal
    );

    el("externalCard").classList.toggle(
        "active",
        !internal
    );

    updateCheckoutPreview();
}

// ======================================================
// DYNAMIC TRANSFER MODAL HEADING
// ======================================================

function updateCheckoutPreview() {
    const radio = document.querySelector(
        'input[name="checkoutType"]:checked'
    );

    if (!radio) return;

    const internal = radio.value === "Internal";

    const externalTo = getValue("externalCheckoutType");

    if (el("checkoutModalTitle")) {
        el("checkoutModalTitle").textContent =
            internal
                ? "Asset Transfer"
                : externalTo === "Company"
                    ? "External Company Transfer"
                    : externalTo === "Supplier"
                        ? "External Supplier Transfer"
                        : "External Transfer";
    }

    if (internal) {
        const destination =
            getValue("internalCheckoutType");

        el("locationField").style.display =
            destination === "Location" ? "" : "none";

        el("userField").style.display =
            destination === "User" ? "" : "none";

        el("assetField").style.display =
            destination === "Asset" ? "" : "none";

        el("internalFormTitle").textContent =
            destination + " Transfer Details";

    } else {
        const supplier = externalTo === "Supplier";

        el("externalSupplierFields").style.display =
            supplier ? "" : "none";

        el("externalCompanyFields").style.display =
            supplier ? "none" : "";

        el("externalFormTitle").textContent =
            (supplier ? "Supplier" : "Company") +
            " Transfer Details";
    }
}

// ======================================================
// VALIDATE SELECTED ASSETS BEFORE TRANSFER
// ======================================================

function validateSelectedForTransfer() {
    clearTransferPrecheckFeedback();

    const blocked = [];

    for (const id of selectedAssets) {
        const asset = gridAssets.get(id);

        if (
            !asset ||
            Number(str(asset.Status).trim()) !== 1
        ) {
            blocked.push({ id, asset });
        }
    }

    if (blocked.length === 0) {
        return true;
    }

    const message =
        "Transfer blocked for barcode ID(s): " +
        blocked.map(({ id }) => id).join(", ") +
        ". Only assets eligible for transfer can be transferred. " +
        "Deselect the red-highlighted row(s).";

    const body = el("assetTableBody");
    let first = null;

    if (body) {
        const ids = new Set(
            blocked.map(item => item.id)
        );

        body.querySelectorAll("tr").forEach(row => {
            if (ids.has(row.dataset.barcodeId)) {
                row.classList.add(
                    "transfer-error-row"
                );

                if (!first) {
                    first = row;
                }
            }
        });
    }

    const errorElement = el("transferPrecheckError");

    if (errorElement) {
        errorElement.textContent = message;
        errorElement.hidden = false;
    }

    notify(message, true);

    if (first && first.scrollIntoView) {
        first.scrollIntoView({
            block: "nearest",
            behavior: "smooth"
        });
    }

    return false;
}

// ======================================================
// OPEN TRANSFER MODAL
// ======================================================

function openCheckoutModal() {
    if (selectedAssets.size === 0) {
        notify(
            "Select at least one asset before transfer.",
            true
        );
        return;
    }

    if (!validateSelectedForTransfer()) {
        return;
    }

    el("checkoutAssetCount").textContent =
        selectedAssets.size;

    el("checkoutValidation").textContent = "";
    el("externalValidation").textContent = "";

    // Clear input values.
    for (const id of [
        "checkoutNote",
        "externalNotes",
        "externalExpectedCheckin"
    ]) {
        if (el(id)) {
            el(id).value = "";
        }
    }

    // Reset dropdowns.
    for (const id of [
        "checkoutLocation",
        "checkoutUser",
        "checkoutAsset",
        "externalSupplier",
        "externalCompany"
    ]) {
        if (el(id)) {
            el(id).selectedIndex = 0;
        }
    }

    // Reset transaction type to Internal.
    const internalRadio = document.querySelector(
        'input[name="checkoutType"][value="Internal"]'
    );

    if (internalRadio) {
        internalRadio.checked = true;
    }

    el("internalCheckoutType").selectedIndex = 0;
    el("externalCheckoutType").selectedIndex = 0;

    restrictExpectedReturnDate();
    changeCheckoutType();

    const modal = el("checkoutModal");

    modal.style.display = "flex";
    modal.classList.add("visible");
    modal.setAttribute("aria-hidden", "false");
}

// ======================================================
// CLOSE TRANSFER MODAL
// ======================================================

function closeCheckoutModal() {
    if (saving) return;

    const modal = el("checkoutModal");

    if (!modal) return;

    modal.classList.remove("visible");
    modal.style.display = "none";
    modal.setAttribute("aria-hidden", "true");
}

// ======================================================
// SAVE TRANSFER TO BACKEND
// SaveCheckout result:
//   Success  -> SweetAlert success popup (Message + Tag)
//   Failure  -> SweetAlert error popup (Message from server)
// ======================================================

async function continueCheckout() {
    if (saving) return;

    if (!validateSelectedForTransfer()) {
        closeCheckoutModal();
        return;
    }

    const radio = document.querySelector(
        'input[name="checkoutType"]:checked'
    );

    if (!radio) return;

    const checkoutType = radio.value;
    const internal = checkoutType === "Internal";

    const destinationType = getValue(
        internal
            ? "internalCheckoutType"
            : "externalCheckoutType"
    );

    const validation = el(
        internal
            ? "checkoutValidation"
            : "externalValidation"
    );

    validation.textContent = "";

    let destinationId = null;
    let supplierId = null;
    let companyId = null;
    let expectedDate = null;

    if (internal) {
        const field =
            destinationType === "Location"
                ? "checkoutLocation"
                : destinationType === "User"
                    ? "checkoutUser"
                    : "checkoutAsset";

        destinationId = getValue(field);

        if (!/^[1-9]\d*$/.test(destinationId)) {
            validation.textContent =
                "Select a valid " +
                destinationType.toLowerCase() + ".";

            return;
        }

    } else {
        if (destinationType === "Supplier") {
            supplierId = getValue("externalSupplier");

            if (!/^[1-9]\d*$/.test(supplierId)) {
                validation.textContent =
                    "Please select a valid supplier.";

                return;
            }

        } else if (destinationType === "Company") {
            companyId = getValue("externalCompany");

            if (!companyId) {
                validation.textContent =
                    "Please select a company.";

                return;
            }

        } else {
            validation.textContent =
                "Invalid external destination type.";

            return;
        }

        expectedDate = getValue(
            "externalExpectedCheckin"
        );

        if (!expectedDate) {
            validation.textContent =
                "Please select an expected check-in date.";

            return;
        }

        restrictExpectedReturnDate();

        const minimumDate =
            el("externalExpectedCheckin").min;

        if (expectedDate < minimumDate) {
            validation.textContent =
                "Past dates are not allowed. " +
                "Please select today or a future date.";

            return;
        }
    }

    if (selectedAssets.size === 0) {
        validation.textContent =
            "Select at least one asset.";

        return;
    }

    const checkout = {
        checkoutType,
        destinationType,
        destinationId,
        supplierId,
        companyId,
        expectedCheckinDate: expectedDate,

        note: getValue(
            internal
                ? "checkoutNote"
                : "externalNotes"
        ),

        barcodeIds: Array.from(selectedAssets)
    };

    const button = el("checkoutContinueButton");

    saving = true;

    button.disabled = true;
    button.textContent = "Transferring...";

    try {
        const response = await callServer(
            "SaveCheckout",
            {
                checkout
            }
        );

        if (!response || !response.Success) {
            throw new Error(
                response && response.Message ||
                "Transfer failed."
            );
        }

        // Clear successfully transferred assets.
        for (const id of selectedAssets) {
            gridAssets.delete(id);
        }

        selectedAssets.clear();

        renderGrid();

        const successMessage =
            (response.Message || "Transfer saved.") +
            " Tag: " +
            str(response.TransactionTag);

        notify(successMessage);

        // Close the transfer dialog first, then show the popup.
        saving = false;
        closeCheckoutModal();

        showAlert(
            "Transfer Successful",
            successMessage,
            "success",
            focusScanner
        );

    } catch (error) {
        const message =
            error.message || "Transfer failed.";

        validation.textContent = message;

        notify(message, true);

        showAlert("Transfer Failed", message, "error");

    } finally {
        saving = false;

        button.disabled = false;
        button.textContent = "Transfer";
    }
}

// ======================================================
// PREVENT PAST EXPECTED RETURN DATES
// ======================================================

function restrictExpectedReturnDate() {
    const dateInput = el("externalExpectedCheckin");

    if (!dateInput) return;

    const now = new Date();

    const today =
        now.getFullYear() + "-" +
        String(now.getMonth() + 1).padStart(2, "0") + "-" +
        String(now.getDate()).padStart(2, "0");

    dateInput.min = today;

    if (dateInput.value && dateInput.value < today) {
        dateInput.value = "";
    }
}

// ======================================================
// OPEN UPDATE CONDITION MODAL
// ======================================================

function openConditionModal() {
    if (selectedAssets.size === 0) {
        notify(
            "Select at least one grid asset to update its condition.",
            true
        );
        return;
    }

    const modal = el("conditionModal");
    const dropdown = el("DPCondition");

    if (!modal) return;

    if (!dropdown) {
        notify("Condition dropdown not found.", true);
        return;
    }

    el("conditionAssetCount").textContent =
        selectedAssets.size;

    el("conditionValidation").textContent = "";

    if (dropdown.options.length > 0) {
        dropdown.selectedIndex = 0;
    }

    modal.style.display = "flex";
    modal.classList.add("visible");
    modal.setAttribute("aria-hidden", "false");

    dropdown.focus();
}

// ======================================================
// CLOSE UPDATE CONDITION MODAL
// ======================================================

function closeConditionModal() {
    const modal = el("conditionModal");

    if (!modal) return;

    modal.classList.remove("visible");
    modal.style.display = "none";
    modal.setAttribute("aria-hidden", "true");
}

// ======================================================
// PREPARE CONDITION POSTBACK
// The result of the postback (success or failure) is shown
// by btnApplyCondition_Click in the .aspx.cs.
// ======================================================

function prepareConditionPostback() {
    const dropdown = el("DPCondition");
    const validation = el("conditionValidation");
    const hiddenField = el("hfConditionBarcodeIds");

    validation.textContent = "";

    if (selectedAssets.size === 0) {
        validation.textContent =
            "Please select at least one asset.";
        return false;
    }

    if (!dropdown.value || dropdown.value === "0") {
        validation.textContent =
            "Please select a valid condition.";
        return false;
    }

    // Send selected barcode IDs to C#
    hiddenField.value =
        Array.from(selectedAssets).join(",");

    // Preserve scanned assets across the postback
    saveTransferState();

    return true;
}

// ======================================================
// PAGE INITIALIZATION
// ======================================================

document.addEventListener("DOMContentLoaded", () => {
    const input = el("barcodeInput");

    if (!input) {
        console.error(
            "barcodeInput element not found."
        );
        return;
    }

    // Scanner Enter key.
    input.addEventListener("keydown", event => {
        if (event.key === "Enter") {
            event.preventDefault();

            clearTimeout(searchTimer);

            handleAssetInput();
        }
    });

    // Text asset searching.
    input.addEventListener("input", () => {
        clearTimeout(searchTimer);

        const value = input.value;

        if (!value.trim()) {
            ++searchSequence;

            if (el("assetSearchResults")) {
                el("assetSearchResults").replaceChildren();
            }

            return;
        }

        searchTimer = setTimeout(() => {
            searchAssets(value);
        }, 250);
    });

    // Prevent scanner Enter from submitting ASP.NET form.
    const form = el("form1");

    if (form) {
        form.addEventListener("keydown", event => {
            if (
                event.key === "Enter" &&
                event.target === input
            ) {
                event.preventDefault();
            }
        });
    }

    // Click outside transfer modal to close.
    const modal = el("checkoutModal");

    if (modal) {
        modal.addEventListener("click", event => {
            if (event.target === modal) {
                closeCheckoutModal();
            }
        });
    }

    // Click outside condition modal to close.
    const conditionModal = el("conditionModal");

    if (conditionModal) {
        conditionModal.addEventListener("click", event => {
            if (event.target === conditionModal) {
                closeConditionModal();
            }
        });
    }

    // Escape closes dialogs.
    document.addEventListener("keydown", event => {
        if (event.key === "Escape") {
            closeCheckoutModal();
            closeConditionModal();
        }
    });

    // ==================================================
    // INITIAL PAGE STATE
    // ==================================================

    restoreTransferState();

    // Always display pending area, even when empty.
    renderPending();

    // Grid rendering also controls footer visibility.
    renderGrid();

    changeCheckoutType();

    input.focus();
});