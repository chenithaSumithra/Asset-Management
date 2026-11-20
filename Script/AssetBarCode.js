
"use strict";

// ==========================================
// GLOBAL VARIABLES
// ==========================================

const $ = id => document.getElementById(id);

const scannedAssets = new Map();
const pendingBarcodes = new Set();

const fields = [
    "BarcodeId",
    "AssetName",
    "Serial",
    "MachineNo",
    "Model",
    "Model_No"
];

let failedScans = 0;
let scanBuffer = "";
let scannerTimer;
let lastKeyTime = 0;

let assetSelectInstance;
let previousModalFocus;
let barcodeInput;
let scannerStatus;

let assetSearchTimer = null;
let assetSearchVersion = 0;
let assetSearchController = null;

// ==========================================
// HELPER FUNCTIONS
// ==========================================

const isCheckoutOpen = () =>
    $("checkoutModal").classList.contains("show");

const getSelectedAssets = () =>
    [...scannedAssets.values()].filter(a => a.selected);

const today = () => {
    const d = new Date();

    return `${d.getFullYear()}-${String(
        d.getMonth() + 1
    ).padStart(2, "0")}-${String(
        d.getDate()
    ).padStart(2, "0")}`;
};

const focusScanner = () => {
    if (!isCheckoutOpen()) {
        barcodeInput?.focus({ preventScroll: true });
    }
};

function showMessage(message, type = "info") {
    const el = $("message");

    el.textContent = message;
    el.className = "message " + type;
    el.style.display = "block";
}

// ==========================================
// COUNTS AND SELECTED ASSETS
// ==========================================

function updateCounts() {
    const selected = getSelectedAssets();
    const total = scannedAssets.size;

    $("totalCount").textContent = total;
    $("selectedCount").textContent = selected.length;
    $("errorCount").textContent = failedScans;
    $("footerSelectedCount").textContent = selected.length;

    $("batchBarcodes").value =
        selected.map(a => a.BarcodeId).join(", ");

    $("emptyMessage").style.display =
        total ? "none" : "block";

    const check = $("selectAllCheckbox");

    check.checked =
        total > 0 && selected.length === total;

    check.indeterminate =
        selected.length > 0 && selected.length < total;
}

// ==========================================
// RENDER EXISTING ASSET GRID
// ==========================================

function renderTable() {
    const tbody = $("assetTableBody");

    tbody.replaceChildren();

    scannedAssets.forEach((asset, id) => {

        const tr = document.createElement("tr");
        const td = document.createElement("td");
        const check = document.createElement("input");

        check.type = "checkbox";
        check.checked = !!asset.selected;

        check.onchange = () => {
            asset.selected = check.checked;
            updateCounts();
        };

        td.append(check);
        tr.append(td);

        fields.forEach(key => {
            const cell = document.createElement("td");

            cell.textContent = asset[key] ?? "-";

            tr.append(cell);
        });

        const action = document.createElement("td");
        const btn = document.createElement("button");

        btn.type = "button";
        btn.className = "remove-btn";
        btn.textContent = "Remove";

        btn.onclick = () => {
            scannedAssets.delete(id);
            renderTable();
            focusScanner();
        };

        action.append(btn);
        tr.append(action);
        tbody.append(tr);
    });

    updateCounts();
}

// ==========================================
// CANCEL OLD LIVE SEARCH
// ==========================================

function cancelAssetSearch(clearResults = true) {

    clearTimeout(assetSearchTimer);
    assetSearchVersion++;

    if (assetSearchController) {
        assetSearchController.abort();
        assetSearchController = null;
    }

    if (clearResults && $("assetSearchResults")) {
        $("assetSearchResults").replaceChildren();
    }
}

// ==========================================
// BARCODE VALIDATION
// ==========================================

function normalizeBarcode(barcode) {

    const raw = String(barcode ?? "").trim();

    if (!/^\d+$/.test(raw)) return null;

    const number = Number(raw);

    if (!Number.isSafeInteger(number) ||
        number <= 0 ||
        number > 2147483647) {
        return null;
    }

    return String(number);
}

// ==========================================
// BARCODE SCANNING
// ==========================================

async function scanBarcode(barcode = barcodeInput.value) {

    const raw = String(barcode ?? "").trim();

    if (!raw) return false;

    const id = normalizeBarcode(raw);

    if (!id) {
        failedScans++;
        showMessage("Invalid numeric barcode.", "error");
        updateCounts();
        return false;
    }

    if (scannedAssets.has(id) ||
        pendingBarcodes.has(id)) {

        showMessage(
            `Barcode ${id} already scanned.`,
            "info"
        );

        return false;
    }

    pendingBarcodes.add(id);

    scannerStatus.textContent = `Processing ${id}...`;

    try {
        const response = await fetch(
            "AssetBarCode.aspx/GetAssetByBarcode",
            {
                method: "POST",
                headers: {
                    "Content-Type":
                        "application/json; charset=utf-8"
                },
                credentials: "same-origin",
                body: JSON.stringify({
                    barcodeId: Number(id)
                })
            }
        );

        if (!response.ok) {
            throw new Error(
                `Server error: ${response.status}`
            );
        }

        const data = await response.json();
        const result = data.d || data;

        if (!result?.Success || !result.Asset) {

            failedScans++;

            showMessage(
                result?.Message || "Asset not found.",
                "error"
            );

            return false;
        }

        scannedAssets.set(id, {
            ...result.Asset,
            BarcodeId: id,
            selected: true
        });

        renderTable();

        showMessage(
            `Asset ${id} added successfully.`,
            "success"
        );

        return true;

    } catch (error) {

        failedScans++;
        console.error("Barcode Error:", error);

        showMessage(
            "Unable to retrieve asset: " + error.message,
            "error"
        );

        return false;

    } finally {

        pendingBarcodes.delete(id);

        scannerStatus.textContent =
            "Scanner Ready - Scan or Search Assets";

        updateCounts();
    }
}

// ==========================================
// SINGLE TEXTBOX: ADD ASSET BUTTON
// ==========================================

async function handleAssetInput() {

    const value = barcodeInput.value.trim();

    if (!value) return;

    // Numeric values are treated as barcode IDs.
    if (/^\d+$/.test(value)) {

        cancelAssetSearch();

        await scanBarcode(value);

        if (barcodeInput.value.trim() === value) {
            barcodeInput.value = "";
        }

        focusScanner();
        return;
    }

    // Text values search the database.
    scheduleAssetSearch(value, true);
}

// ==========================================
// INITIALIZE SEARCH ON SAME TEXTBOX
// ==========================================

function initializeUnifiedAssetSearch() {

    const input = $("barcodeInput");
    const results = $("assetSearchResults");

    if (!input || !results) {
        console.error("Asset search elements not found.");
        return;
    }

    input.addEventListener("input", function () {

        const search = input.value.trim();

        cancelAssetSearch();

        if (!search) return;

        scheduleAssetSearch(search);
    });

    input.addEventListener("focus", function () {

        const search = input.value.trim();

        if (search && !results.children.length) {
            scheduleAssetSearch(search);
        }
    });

    document.addEventListener("click", function (event) {

        if (event.target === input ||
            results.contains(event.target) ||
            event.target.closest(".scan-row")) {
            return;
        }

        cancelAssetSearch();
    });
}

// ==========================================
// DEBOUNCED LIVE SEARCH
// ==========================================

function scheduleAssetSearch(search, immediate = false) {

    clearTimeout(assetSearchTimer);

    const version = ++assetSearchVersion;

    const results = $("assetSearchResults");

    results.textContent = "Searching assets...";

    assetSearchTimer = setTimeout(() => {

        searchAssets(search, version);

    }, immediate ? 0 : 350);
}

// ==========================================
// SEARCH ASSETS
// ==========================================

async function searchAssets(search, version) {

    if (assetSearchController) {
        assetSearchController.abort();
    }

    const controller = new AbortController();
    assetSearchController = controller;

    try {
        const response = await fetch(
            "AssetBarCode.aspx/SearchAssets",
            {
                method: "POST",
                headers: {
                    "Content-Type":
                        "application/json; charset=utf-8"
                },
                credentials: "same-origin",
                signal: controller.signal,
                body: JSON.stringify({
                    search: search
                })
            }
        );

        if (!response.ok) {
            throw new Error(
                "Server error: " + response.status
            );
        }

        const data = await response.json();
        const result = data.d || data;

        if (version !== assetSearchVersion) return;

        if (search !== barcodeInput.value.trim()) return;

        if (!result?.Success) {
            throw new Error(
                result?.Message || "Asset search failed."
            );
        }

        displayAssetSearchResults(result.Assets || []);

    } catch (error) {

        if (error.name === "AbortError") return;

        if (version !== assetSearchVersion) return;

        console.error("Asset Search Error:", error);

        $("assetSearchResults").textContent =
            "Unable to search assets.";

    } finally {

        if (assetSearchController === controller) {
            assetSearchController = null;
        }
    }
}

// ==========================================
// DISPLAY MATCHING SEARCH RESULTS
// ==========================================

function displayAssetSearchResults(assets) {

    const container = $("assetSearchResults");

    container.replaceChildren();

    if (!assets.length) {
        container.textContent = "No matching assets found.";
        return;
    }

    assets.forEach(asset => {

        const barcode = String(
            asset.BarcodeId ?? ""
        ).trim();

        const id = normalizeBarcode(barcode);

        const row = document.createElement("div");
        row.className = "asset-search-result";

        const information = document.createElement("div");
        information.className = "asset-search-details";

        const name = document.createElement("strong");

        name.textContent =
            asset.AssetName || "Unnamed Asset";

        const description = document.createElement("small");

        description.textContent =
            `Barcode: ${barcode || "-"} | ` +
            `Model: ${asset.Model || "-"} | ` +
            `Serial: ${asset.Serial || "-"} | ` +
            `Machine: ${asset.MachineNo || "-"}`;

        const extra = document.createElement("small");

        extra.textContent =
            `Company: ${asset.Company || "-"} | ` +
            `Location: ${asset.Location || "-"}`;

        information.append(
            name,
            description,
            extra
        );

        const button = document.createElement("button");

        button.type = "button";
        button.className = "asset-search-add-btn";

        const exists = id &&
            (scannedAssets.has(id) ||
                pendingBarcodes.has(id));

        button.textContent =
            !id ? "Unavailable" :
                exists ? "Added" : "Add";

        button.disabled = !id || !!exists;

        button.addEventListener("click", async function () {

            if (button.disabled) return;

            button.disabled = true;
            button.textContent = "Adding...";

            const added = await scanBarcode(id);

            if (added) {

                cancelAssetSearch();

                barcodeInput.value = "";

                focusScanner();

            } else {

                const alreadyExists =
                    scannedAssets.has(id) ||
                    pendingBarcodes.has(id);

                button.textContent =
                    alreadyExists ? "Added" : "Add";

                button.disabled = alreadyExists;
            }
        });

        row.append(information, button);
        container.appendChild(row);
    });
}

// ==========================================
// PHYSICAL BARCODE SCANNER LISTENER
// ==========================================

function handleScannerKeyboard(e) {

    if (isCheckoutOpen() ||
        e.ctrlKey ||
        e.altKey ||
        e.metaKey ||
        e.isComposing) {
        return;
    }

    const inBarcode = e.target === barcodeInput;

    if (e.target instanceof Element &&
        (e.target.matches(
            "input:not(#barcodeInput),textarea,select,button"
        ) || e.target.isContentEditable)) {
        return;
    }

    if (e.key === "Enter") {

        if (inBarcode) {

            e.preventDefault();

            if (barcodeInput.value.trim()) {
                handleAssetInput();
            }

        } else if (
            scanBuffer.length >= 3 &&
            /^\d+$/.test(scanBuffer)
        ) {

            e.preventDefault();

            cancelAssetSearch();

            const barcode = scanBuffer;
            scanBarcode(barcode);
        }

        scanBuffer = "";
        clearTimeout(scannerTimer);

        return;
    }

    if (!inBarcode && e.key.length === 1) {

        const now = performance.now();

        if (now - lastKeyTime > 150) {
            scanBuffer = "";
        }

        lastKeyTime = now;
        scanBuffer += e.key;

        clearTimeout(scannerTimer);

        scannerTimer = setTimeout(() => {
            scanBuffer = "";
        }, 150);
    }
}

// ==========================================
// ASSET SELECTION
// ==========================================

function toggleSelectAll(checked) {

    scannedAssets.forEach(a => {
        a.selected = checked;
    });

    renderTable();
    focusScanner();
}

function selectAllAssets() {
    toggleSelectAll(true);
}

function deselectAllAssets() {
    toggleSelectAll(false);
}

function clearAllBarcodes() {

    if (!scannedAssets.size ||
        !confirm("Clear all scanned assets?")) {
        return;
    }

    scannedAssets.clear();

    renderTable();

    showMessage(
        "All assets cleared.",
        "info"
    );

    focusScanner();
}

// ==========================================
// CSV EXPORT
// ==========================================

function exportSelectedCSV() {

    const selected = getSelectedAssets();

    if (!selected.length) {
        return showMessage(
            "Select assets to export.",
            "error"
        );
    }

    const csvValue = value => {

        let text = String(value ?? "");

        if (/^\s*[=+\-@]/.test(text)) {
            text = "'" + text;
        }

        return `"${text.replace(/"/g, '""')}"`;
    };

    const rows = [
        fields.join(","),
        ...selected.map(a =>
            fields.map(f => csvValue(a[f])).join(",")
        )
    ];

    const blob = new Blob(
        ["\uFEFF" + rows.join("\r\n")],
        {
            type: "text/csv;charset=utf-8;"
        }
    );

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "Asset_Bulk_Batch.csv";

    document.body.append(link);
    link.click();
    link.remove();

    setTimeout(() => URL.revokeObjectURL(url), 1000);
}

// ==========================================
// OPEN CHECKOUT MODAL
// ==========================================

function openCheckoutModal() {

    const selected = getSelectedAssets();

    if (!selected.length) {
        return showMessage(
            "Select at least one asset before checkout.",
            "error"
        );
    }

    cancelAssetSearch();

    previousModalFocus = document.activeElement;

    $("checkoutAssetCount").textContent =
        selected.length;

    document.querySelector(
        'input[name="checkoutType"][value="Internal"]'
    ).checked = true;

    $("internalCheckoutType").value = "Location";
    $("externalCheckoutType").value = "Supplier";



    [
        "checkoutLocation",
        "checkoutUser",
        "expectedCheckinDate",
        "checkoutNote",
        "externalSupplier",
        "externalCompany",
        "externalExpectedCheckin",
        "externalNotes"
    ].forEach(id => {

        const element = $(id);

        if (!element) {
            console.warn("Element not found: ", id);
            return;
        }

        if (element.tagName === "SELECT") {
            element.selectedIndex = 0;
        }
        else {
            element.value = "";
        }
    });

    if (assetSelectInstance) {
        assetSelectInstance.clear(true);
    } else {
        $("checkoutAsset").value = "";
    }

    // Checkout date is generated automatically.
    const date = today();

    [
        "expectedCheckinDate",
        "externalExpectedCheckin"
    ].forEach(id => {
        $(id).min = date;
    });

    changeCheckoutType();

    [
        "checkoutValidation",
        "externalValidation"
    ].forEach(id => {
        $(id).style.display = "none";
    });

    scanBuffer = "";
    clearTimeout(scannerTimer);

    const modal = $("checkoutModal");

    modal.querySelector(".modal-body").scrollTop = 0;

    modal.classList.add("show");
    modal.setAttribute("aria-hidden", "false");

    document.body.classList.add("modal-open");

    modal.querySelector(".modal-close").focus();
}

// ==========================================
// CLOSE CHECKOUT MODAL
// ==========================================

function closeCheckoutModal() {

    const modal = $("checkoutModal");

    modal.classList.remove("show");
    modal.setAttribute("aria-hidden", "true");

    document.body.classList.remove("modal-open");

    if (previousModalFocus?.isConnected) {
        previousModalFocus.focus({
            preventScroll: true
        });
    } else {
        focusScanner();
    }
}

// ==========================================
// CHECKOUT TYPE
// ==========================================

function changeCheckoutType() {

    const internal = document.querySelector(
        'input[name="checkoutType"]:checked'
    ).value === "Internal";

    $("internalSection").style.display =
        internal ? "block" : "none";

    $("externalSection").style.display =
        internal ? "none" : "block";

    $("internalCard").classList.toggle(
        "active",
        internal
    );

    $("externalCard").classList.toggle(
        "active",
        !internal
    );

    updateCheckoutPreview();
}

// ==========================================
// CHECKOUT FORM PREVIEW
// ==========================================

function updateCheckoutPreview() {

    const internal = document.querySelector(
        'input[name="checkoutType"]:checked'
    ).value === "Internal";

    const target = $("internalCheckoutType").value;
    const external = $("externalCheckoutType").value;

    $("internalFields").style.display =
        internal ? "block" : "none";

    $("externalFields").style.display =
        internal ? "none" : "block";

    ["Location", "User", "Asset"].forEach(type => {

        $(type.toLowerCase() + "Field").style.display =
            internal && target === type
                ? "block"
                : "none";
    });

    $("internalFormTitle").textContent =
        target + " Checkout Details";

    $("externalFormTitle").textContent =
        external + " Checkout Details";

    $("externalSupplierFields").style.display =
        !internal && external === "Supplier"
            ? "block"
            : "none";

    $("externalCompanyFields").style.display =
        !internal && external === "Company"
            ? "block"
            : "none";

    $("checkoutContinueButton").disabled = false;

    [
        "checkoutValidation",
        "externalValidation"
    ].forEach(id => {
        $(id).style.display = "none";
    });

    // Return type is always Return.
    // Expected check-in date is required.
    $("externalExpectedCheckin").required = !internal;
}

// ==========================================
// VALIDATION MESSAGE
// ==========================================

function displayValidation(id, message) {

    const el = $(id);

    el.textContent = message;
    el.style.display = "block";

    el.scrollIntoView({
        behavior: "smooth",
        block: "nearest"
    });
}

// ==========================================
// CHECKOUT PROCESS
// ==========================================

async function continueCheckout() {

    const type = document.querySelector(
        'input[name="checkoutType"]:checked'
    ).value;

    const selected = getSelectedAssets();

    if (!selected.length) {
        showMessage(
            "No assets selected for checkout.",
            "error"
        );
        return;
    }

    let payload;

    const validationId =
        type === "Internal"
            ? "checkoutValidation"
            : "externalValidation";

    $(validationId).style.display = "none";

    // ==================================
    // INTERNAL CHECKOUT
    // ==================================

    if (type === "Internal") {

        const target = $("internalCheckoutType").value;

        const id = $(
            target === "Location" ? "checkoutLocation" :
                target === "User" ? "checkoutUser" :
                    "checkoutAsset"
        ).value;

        // Automatically generate checkout date.
        const date = today();

        const checkin = $("expectedCheckinDate").value;

        if (!id) {
            return displayValidation(
                validationId,
                `Please select a ${target.toLowerCase()}.`
            );
        }

        if (!checkin) {
            return displayValidation(
                validationId,
                "Please select an expected check-in date."
            );
        }

        if (checkin < date) {
            return displayValidation(
                validationId,
                "Check-in cannot be before checkout."
            );
        }

        payload = {
            checkoutType: type,
            destinationType: target,
            destinationId: id,
            checkoutDate: date,
            expectedCheckinDate: checkin,
            note: $("checkoutNote").value.trim()
        };

    } else {

        // ==================================
        // EXTERNAL CHECKOUT
        // ==================================

        const target = $("externalCheckoutType").value;

        // Hardcoded Return Type
        const returnType = "Return";

        const supplier = $("externalSupplier").value;
        const company = $("externalCompany").value;

        // Automatically generate checkout date.
        const date = today();

        const checkin = $("externalExpectedCheckin").value;

        // Manager validation removed.

        if (target === "Supplier" && !supplier) {
            return displayValidation(
                validationId,
                "Please select a Supplier."
            );
        }

        if (target === "Company" && !company) {
            return displayValidation(
                validationId,
                "Please select a Company."
            );
        }

        if (!checkin) {
            return displayValidation(
                validationId,
                "Please select an expected check-in date."
            );
        }

        if (checkin < date) {
            return displayValidation(
                validationId,
                "Check-in cannot be before checkout."
            );
        }

        payload = {
            checkoutType: type,
            destinationType: target,

            // Manager removed from UI.
            managerId: null,

            supplierId:
                target === "Supplier" ? supplier : null,

            companyId:
                target === "Company" ? company : null,

            // Hardcoded return type.
            returnType: returnType,

            // Automatically generated date.
            checkoutDate: date,

            expectedCheckinDate: checkin,

            note: $("externalNotes").value.trim()
        };
    }

    // ==================================
    // SELECTED BARCODES
    // ==================================

    payload.barcodeIds =
        selected.map(a => a.BarcodeId);

    console.log("Sending Checkout JSON:", payload);

    const button = $("checkoutContinueButton");

    button.disabled = true;
    button.textContent = "Processing...";

    try {

        const response = await fetch(
            "AssetBarCode.aspx/SaveCheckout",
            {
                method: "POST",
                headers: {
                    "Content-Type":
                        "application/json; charset=utf-8"
                },
                credentials: "same-origin",
                body: JSON.stringify({
                    checkout: payload
                })
            }
        );

        if (!response.ok) {
            throw new Error(
                "Server error: " + response.status
            );
        }

        const data = await response.json();
        const result = data.d || data;

        console.log("Server Response:", result);

        if (!result || !result.Success) {
            throw new Error(
                result?.Message || "Checkout failed."
            );
        }

        closeCheckoutModal();

        // Remove assets only after server success.
        selected.forEach(asset => {
            scannedAssets.delete(
                String(asset.BarcodeId)
            );
        });

        renderTable();

        showMessage(
            result.Message ||
            "Checkout request processed successfully.",
            "success"
        );

        const messageElement = $("message");

        if (messageElement) {
            messageElement.scrollIntoView({
                behavior: "smooth",
                block: "center"
            });
        }

        console.log("Checkout Success:", result);

    } catch (error) {

        console.error("Checkout Error:", error);

        displayValidation(
            validationId,
            error.message ||
            "Unable to complete checkout."
        );

    } finally {

        button.disabled = false;
        button.textContent = "Continue";
    }
}

// ==========================================
// INITIALIZATION
// ==========================================

function initializeAssetBarcode() {

    barcodeInput = $("barcodeInput");
    scannerStatus = $("scannerStatus");

    if (!barcodeInput) {
        console.error("Barcode input not found.");
        return;
    }

    initializeUnifiedAssetSearch();

    // Existing asset select dropdown.
    if (
        typeof TomSelect !== "undefined" &&
        $("checkoutAsset")
    ) {

        assetSelectInstance = new TomSelect(
            "#checkoutAsset",
            {
                create: false,
                allowEmptyOption: true,
                maxItems: 1,

                placeholder: "Search asset ID or name...",

                searchField: [
                    "text",
                    "value"
                ],

                sortField: {
                    field: "text",
                    direction: "asc"
                }
            }
        );
    }

    // Close modal on backdrop click.
    $("checkoutModal").addEventListener(
        "click",
        e => {
            if (e.target === $("checkoutModal")) {
                closeCheckoutModal();
            }
        }
    );

    // Physical scanner keyboard handler.
    document.addEventListener(
        "keydown",
        handleScannerKeyboard
    );

    // Modal keyboard controls.
    document.addEventListener("keydown", e => {

        if (!isCheckoutOpen()) return;

        if (e.key === "Escape") {
            e.preventDefault();
            closeCheckoutModal();
        }

        if (e.key !== "Tab") return;

        const focusable = [
            ...$("checkoutModal").querySelectorAll(
                "button:not(:disabled)," +
                "input:not(:disabled)," +
                "select:not(:disabled)," +
                "textarea:not(:disabled)"
            )
        ].filter(el => el.getClientRects().length);

        if (!focusable.length) return;

        const first = focusable[0];
        const last = focusable[focusable.length - 1];

        if (e.shiftKey &&
            document.activeElement === first) {

            e.preventDefault();
            last.focus();

        } else if (
            !e.shiftKey &&
            document.activeElement === last
        ) {

            e.preventDefault();
            first.focus();
        }

    }, true);

    // Prevent ASP.NET form submission.
    $("form1").addEventListener(
        "submit",
        e => e.preventDefault()
    );

    window.addEventListener("focus", () => {

        if (document.activeElement === document.body) {
            focusScanner();
        }
    });

    updateCounts();
    focusScanner();

    console.log(
        "Asset Barcode Scanner and Live Search Initialized"
    );
}

// ==========================================
// DOCUMENT READY
// ==========================================

if (document.readyState === "loading") {

    document.addEventListener(
        "DOMContentLoaded",
        initializeAssetBarcode,
        { once: true }
    );

} else {

    initializeAssetBarcode();
}

// ==========================================
// GLOBAL FUNCTIONS FOR ASPX BUTTONS
// ==========================================

Object.assign(window, {
    scanBarcode,
    handleAssetInput,
    selectAllAssets,
    deselectAllAssets,
    toggleSelectAll,
    clearAllBarcodes,
    exportSelectedCSV,
    openCheckoutModal,
    closeCheckoutModal,
    changeCheckoutType,
    updateCheckoutPreview,
    continueCheckout
});
