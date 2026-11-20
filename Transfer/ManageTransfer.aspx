<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="ManageTransfer.aspx.cs"
    Inherits="Asset_Management.Transfer.ManageTransfer" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Asset Barcode Scanner | Bulk Transfer</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <link rel="stylesheet" href="../Style/AssetBarCode.css" />
    <link rel="stylesheet" href="../Style/ManageTransfer-additions.css" />
    <link rel="stylesheet" href="../Style/Header.css" />
    <link rel="stylesheet" href="../Vendor/fonts/inter/inter.css" />
    <%--<script src="../Vendor/sweetalert2/sweetalert2.all.min.js"></script>--%>

    <link rel="stylesheet" href="../Vendor/fontawesome/css/all.min.css" />
    <script src="../Script/ManageTransfer.js" defer></script>
</head>

<body>
    <form id="form1" runat="server">

        <div class="container">

            <!-- SCANNER AND SEARCH -->
            <div class="card">

                <div class="transfer-page-header">

                    <a href='<%= ResolveUrl("~/Home.aspx") %>'
                        class="transfer-home-btn"
                        title="Home"
                        aria-label="Go to Home">

                        <svg xmlns="http://www.w3.org/2000/svg"
                            width="23" height="23"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round">
                            <path d="m3 10 9-7 9 7" />
                            <path d="M5 9v12h14V9" />
                            <path d="M9 21v-7h6v7" />
                        </svg>
                    </a>

                    <%--<div class="transfer-page-heading">
                        <h2 class="page-title">Asset Barcode Scanner
                        </h2>
                        <p class="description">
                            Scan QR Code or Search Assets to Prepare Bulk Transfers.
                        </p>
                    </div>--%>



                </div>

                <!-- SCANNER STATUS -->
                <div class="scanner-status">
                    <span class="scanner-dot"></span>
                    <span id="scannerStatus">Scanner Ready - Scan a QR Code
                    </span>
                </div>

                <!-- SCANNER INPUT -->
                <div class="scan-row">

                    <input type="text"
                        id="barcodeInput"
                        class="scan-input"
                        placeholder="Scan QR / Search Asset"
                        autocomplete="off"
                        autofocus="autofocus" />

                    <button type="button"
                        id="addItemsButton"
                        class="btn"
                        onclick="addItemsToGrid()">
                        Add Items
                    </button>

                    <button type="button"
                        class="btn btn-danger"
                        onclick="clearAllBarcodes()">
                        Remove All Items
                    </button>

                </div>

                <!-- SEARCH RESULTS -->
                <div id="assetSearchResults"
                    class="asset-search-results"
                    role="status"
                    aria-live="polite">
                </div>

                <!-- PENDING SCANNED ASSETS -->
                <div class="staging-panel" id="pendingStagingPanel" hidden>

                    <div class="toolbar">
                        <h3 class="section-title">Scanned / Pending Assets
                        <span id="pendingCount">(0)</span>
                        </h3>
                    </div>

                    <!-- ALWAYS VISIBLE EVEN WHEN EMPTY -->
                    <div id="pendingAssetList"
                        class="pending-asset-list"
                        aria-live="polite"
                        hidden>
                    </div>

                    <p class="description">
                        Scanned assets appear above.
                    Remove individual items using X,
                    or click Add Items to move them into the grid.
                    </p>

                </div>



                <div id="message"
                    class="message"
                    role="status"
                    aria-live="polite">
                </div>

                <!-- STATISTICS -->
                <div class="stats">

                    <div class="stat">
                        <strong id="AssetCount">
                            <asp:Literal ID="litTotalAssets"
                                runat="server"
                                Text="0" />
                        </strong>
                        <span>Total Asset Available for Checkout</span>
                    </div>

                    <div class="stat">
                        <strong id="totalCount">0</strong>
                        <span>Total Scanned</span>
                    </div>

                    <div class="stat">
                        <strong id="selectedCount">0</strong>
                        <span>Selected for Batch</span>
                    </div>

                    <div class="stat">
                        <strong id="errorCount">0</strong>
                        <span>Failed Scans</span>
                    </div>

                </div>
            </div>

            <!-- SCANNED ASSET DETAILS -->
            <div class="card">

                <div class="toolbar">

                    <h2 class="section-title">Scanned Asset Details
                    </h2>

                    <div class="actions">

                        <button type="button"
                            class="btn btn-light"
                            onclick="selectAllAssets()">
                            Select All
                        </button>

                        <button type="button"
                            class="btn btn-light"
                            onclick="deselectAllAssets()">
                            Deselect All
                        </button>

                        <button type="button"
                            class="btn btn-light"
                            id="refreshPageButton"
                            onclick="refreshManageTransferPage()">
                            Refresh Page
                        </button>

                    </div>
                </div>

                <!-- ASSET GRID -->
                <div class="table-wrapper">
                    <table>
                        <thead>
                            <tr>
                                <th>
                                    <input type="checkbox"
                                        id="selectAllCheckbox"
                                        aria-label="Select all assets"
                                        onchange="toggleSelectAll(this.checked)" />
                                </th>
                                <th>Barcode ID</th>
                                <th>Asset Name</th>
                                <th>Serial</th>
                                <th>Machine No</th>
                                <th>Model</th>
                                <th>Model No</th>
                                <th>Company</th>
                                <th>C. Locations</th>
                                <th>Status</th>
                                <th>Condition</th>
                                <th>Action</th>
                            </tr>
                        </thead>

                        <tbody id="assetTableBody">
                        </tbody>
                    </table>
                </div>

                <div id="emptyMessage" class="empty">
                    No assets added to the grid yet.
                </div>

            </div>

            <!-- BULK TRANSFER BATCH -->
            <div class="card">

                <h2 class="section-title">Bulk Transfer Batch
                </h2>

                <p class="description">
                    Select the assets you want to transfer.
                </p>

                <label class="batch-label" for="batchBarcodes">
                    Selected Barcode IDs
                </label>

                <textarea id="batchBarcodes"
                    class="batch-output"
                    readonly="readonly"></textarea>
            </div>

        </div>

        <!-- FIXED FOOTER -->
        <div class="batch-fixed-footer">

            <div id="transferPrecheckError"
                role="alert"
                aria-live="assertive"
                hidden="hidden">
            </div>

            <div class="batch-footer-content">

                <div class="batch-footer-info">

                    <span class="batch-footer-title">Bulk Asset Transactions
                    </span>

                    <span class="batch-footer-subtitle">
                        <strong id="footerSelectedCount">0</strong>
                        assets selected for transfer
                    </span>

                </div>

                <div class="batch-footer-actions">

                    <!-- HIDDEN UNTIL ITEMS ENTER GRID -->
                    <button type="button"
                        id="transferButton"
                        class="btn checkout-button"
                        style="display: none;"
                        hidden="hidden"
                        onclick="openCheckoutModal()">
                        Transfer
                    </button>

                    <!-- REPLACES EXPORT BATCH CSV -->
                    <button type="button"
                        id="updateConditionButton"
                        class="btn condition-button"
                        style="display: none;"
                        hidden="hidden"
                        onclick="openConditionModal()">
                        Update Condition
                    </button>

                </div>
            </div>
        </div>

        <!-- UPDATE CONDITION MODAL -->
        <div id="conditionModal"
            class="checkout-overlay"
            role="dialog"
            aria-modal="true"
            aria-labelledby="conditionModalTitle"
            aria-hidden="true"
            style="display: none;">

            <div class="checkout-modal condition-modal-box">

                <div class="modal-header">

                    <div class="modal-heading">

                        <div class="modal-icon">
                            &#9998;
                        </div>

                        <div>
                            <h2 id="conditionModalTitle">Update Asset Condition
                            </h2>
                            <p>
                                Apply a condition to selected assets in the current batch
                            </p>
                        </div>

                    </div>

                    <button type="button"
                        class="modal-close"
                        aria-label="Close condition editor"
                        onclick="closeConditionModal()">
                        &times;
                    </button>

                </div>

                <div class="modal-body">

                    <div class="asset-summary">
                        <span>Selected Assets</span>
                        <strong id="conditionAssetCount">0</strong>
                    </div>

                    <div class="form-field">
                        <label class="field-label" for="DPCondition">
                            New Condition *
                        </label>


                        <asp:DropDownList
                            ID="DPCondition"
                            runat="server"
                            ClientIDMode="Static"
                            CssClass="checkout-input">
                        </asp:DropDownList>
                    </div>

                    <p class="description condition-notice">
                        This changes the condition in the current browser batch only.
                    It does not update the SQL database.
                    </p>

                    <div id="conditionValidation"
                        class="validation-error"
                        role="alert">
                    </div>

                </div>

                <div class="modal-footer">

                    <button type="button"
                        class="modal-cancel"
                        onclick="closeConditionModal()">
                        Cancel
                    </button>

                    <%-- <button type="button"
                        class="modal-continue"
                        onclick="applyConditionUpdate()">
                    Apply Condition
                </button>--%>

                    <asp:Button
                        ID="btnApplyCondition"
                        runat="server"
                        Text="Apply Condition"
                        CssClass="modal-continue"
                        OnClientClick="return  prepareConditionPostback();"
                        OnClick="btnApplyCondition_Click" />

                    <asp:HiddenField ID="hfConditionBarcodeIds"
                        runat="server"
                        ClientIDMode="Static" />
                </div>
            </div>
        </div>

        <!-- TRANSFER MODAL -->
        <div id="checkoutModal"
            class="checkout-overlay"
            role="dialog"
            aria-modal="true"
            aria-labelledby="checkoutModalTitle"
            aria-hidden="true"
            style="display: none;">

            <div class="checkout-modal">

                <!-- MODAL HEADER -->
                <div class="modal-header">

                    <div class="modal-heading">

                        <div class="modal-icon">
                            &#8599;
                        </div>

                        <div>
                            <h2 id="checkoutModalTitle">Asset Transfer
                            </h2>

                            <p>
                                Configure your bulk asset transaction
                            </p>
                        </div>

                    </div>

                    <button type="button"
                        class="modal-close"
                        aria-label="Close transfer"
                        onclick="closeCheckoutModal()">
                        &times;
                    </button>

                </div>

                <div class="modal-body">

                    <!-- SELECTED ASSETS SUMMARY -->
                    <div class="asset-summary">
                        <span>Selected Assets for Transfer</span>
                        <strong id="checkoutAssetCount">0</strong>
                    </div>

                    <!-- TRANSACTION TYPE -->
                    <div class="step-heading">
                        <span class="step-number">01</span>
                        Choose Transaction Type
                    </div>

                    <div class="type-grid">

                        <!-- INTERNAL -->
                        <label class="type-card active" id="internalCard">

                            <input type="radio"
                                name="checkoutType"
                                value="Internal"
                                checked="checked"
                                onchange="changeCheckoutType()" />

                            <span class="type-icon">&#8962;
                            </span>

                            <span class="type-name">Internal
                            </span>

                            <span class="type-desc">Transfer within the organization
                            </span>

                        </label>

                        <!-- EXTERNAL -->
                        <label class="type-card" id="externalCard">

                            <input type="radio"
                                name="checkoutType"
                                value="External"
                                onchange="changeCheckoutType()" />

                            <span class="type-icon">&#8599;
                            </span>

                            <span class="type-name">External
                            </span>

                            <span class="type-desc">Transfer outside the organization
                            </span>

                        </label>

                    </div>

                    <!-- INTERNAL DESTINATION -->
                    <div id="internalSection" class="type-section">

                        <div class="step-heading">
                            <span class="step-number">02</span>
                            Internal Transfer Type
                        </div>

                        <label class="field-label" for="internalCheckoutType">
                            Transfer To
                        </label>

                        <select id="internalCheckoutType"
                            class="checkout-select"
                            onchange="updateCheckoutPreview()">

                            <option value="Location">Location</option>

                            <%--
                        Enable these options once the dropdowns are loaded:

                        <option value="User">User</option>
                        <option value="Asset">Asset</option>
                            --%>
                        </select>
                    </div>

                    <!-- EXTERNAL DESTINATION -->
                    <div id="externalSection"
                        class="type-section"
                        style="display: none;">

                        <div class="step-heading">
                            <span class="step-number">02</span>
                            External Transfer Type
                        </div>

                        <label class="field-label" for="externalCheckoutType">
                            Transfer To
                        </label>

                        <select id="externalCheckoutType"
                            class="checkout-select"
                            onchange="updateCheckoutPreview()">

                            <option value="Supplier">Supplier</option>
                            <option value="Company">Company</option>

                        </select>

                    </div>

                    <!-- INTERNAL TRANSFER FIELDS -->
                    <div id="internalFields" class="checkout-form-panel">

                        <h3 id="internalFormTitle"
                            class="checkout-form-title">Location Transfer Details
                        </h3>

                        <!-- LOCATION -->
                        <div id="locationField" class="form-field">

                            <label class="field-label" for="checkoutLocation">
                                Select Location *
                            </label>

                            <asp:DropDownList
                                ID="checkoutLocation"
                                runat="server"
                                ClientIDMode="Static"
                                CssClass="checkout-select">
                            </asp:DropDownList>

                        </div>

                        <!-- USER -->
                        <div id="userField"
                            class="form-field"
                            style="display: none;">

                            <label class="field-label" for="checkoutUser">
                                Select User *
                            </label>

                            <select id="checkoutUser" class="checkout-select">
                                <option value="">-- Select User --</option>
                            </select>

                        </div>

                        <!-- ASSET -->
                        <div id="assetField"
                            class="form-field"
                            style="display: none;">

                            <label class="field-label" for="checkoutAsset">
                                Select Asset *
                            </label>

                            <select id="checkoutAsset" class="checkout-select">
                                <option value="">-- Select Asset --</option>
                            </select>

                        </div>

                        <!-- INTERNAL NOTES -->
                        <div class="form-field">

                            <label class="field-label" for="checkoutNote">
                                Note
                            </label>

                            <textarea id="checkoutNote"
                                class="checkout-input checkout-note"
                                maxlength="2000"
                                placeholder="Enter internal transfer notes..."></textarea>
                        </div>

                        <div id="checkoutValidation"
                            class="validation-error"
                            role="alert">
                        </div>

                    </div>

                    <!-- EXTERNAL TRANSFER FIELDS -->
                    <div id="externalFields"
                        class="checkout-form-panel"
                        style="display: none;">

                        <h3 id="externalFormTitle"
                            class="checkout-form-title">Supplier Transfer Details
                        </h3>

                        <!-- SUPPLIER -->
                        <div id="externalSupplierFields">

                            <div class="form-field">

                                <label class="field-label" for="externalSupplier">
                                    Select Supplier *
                                </label>

                                <asp:DropDownList
                                    ID="externalSupplier"
                                    runat="server"
                                    ClientIDMode="Static"
                                    CssClass="checkout-select">
                                </asp:DropDownList>

                            </div>

                        </div>

                        <!-- COMPANY -->
                        <div id="externalCompanyFields"
                            style="display: none;">

                            <div class="form-field">

                                <label class="field-label" for="externalCompany">
                                    Select Company *
                                </label>

                                <asp:DropDownList
                                    ID="externalCompany"
                                    runat="server"
                                    ClientIDMode="Static"
                                    CssClass="checkout-select">
                                </asp:DropDownList>

                            </div>
                        </div>

                        <!-- EXPECTED RETURN DATE -->
                        <div class="form-grid">

                            <div id="externalExpectedDateField"
                                class="form-field">

                                <label class="field-label"
                                    for="externalExpectedCheckin">
                                    Expected Returned Date *
                                </label>

                                <input id="externalExpectedCheckin"
                                    class="checkout-input"
                                    type="date" />

                            </div>

                        </div>

                        <!-- EXTERNAL NOTES -->
                        <div class="form-field">

                            <label class="field-label" for="externalNotes">
                                Notes
                            </label>

                            <textarea id="externalNotes"
                                class="checkout-input checkout-note"
                                maxlength="2000"
                                placeholder="Enter external transfer notes..."></textarea>

                        </div>

                        <div id="externalValidation"
                            class="validation-error"
                            role="alert">
                        </div>

                    </div>

                </div>

                <!-- MODAL FOOTER -->
                <div class="modal-footer">

                    <button type="button"
                        class="modal-cancel"
                        onclick="closeCheckoutModal()">
                        Cancel
                    </button>

                    <button type="button"
                        class="modal-continue"
                        id="checkoutContinueButton"
                        onclick="continueCheckout()">
                        Transfer
                    </button>

                </div>

            </div>
        </div>

    </form>
</body>
</html>
