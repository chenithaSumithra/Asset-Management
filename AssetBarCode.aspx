<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="AssetBarCode.aspx.cs"
    Inherits="Asset_Management.AssetBarCode" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Asset Barcode Scanner | Bulk Checkout</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="Style/AssetBarCode.css" />


    <script src="Script/AssetBarCode.js?v=4" defer></script>


</head>

<body>
    <form id="form1" runat="server">

        <div class="container">

            <!-- BARCODE SCANNER -->

            <div class="card">

                <h2 class="page-title">Asset Barcode Scanner
                </h2>

                <p class="description">
                    Scan QR codes or barcodes to automatically
                retrieve asset details and prepare bulk transactions.
                </p>

                <div class="scan-row">

                    <input type="text"
                        id="barcodeInput"
                        class="scan-input"
                        placeholder="Scan QR / Search Asset Scan"
                        autocomplete="off"
                        autofocus="autofocus" />

                    <button type="button"
                        class="btn"
                        onclick="handleAssetInput()">
                        Add Asset
                    </button>

                </div>

                <div id="assetSearchResults"
                    class="asset-search-results"
                    role="status"
                    aria-live="polite"
                    ></div>

                <div class="scanner-status">
                    <span class="scanner-dot"></span>
                    <span id="scannerStatus">Scanner Ready - Scan a QR Code
                    </span>
                </div>

              

                <div id="message"
                    class="message"
                    role="status"
                    aria-live="polite">
                </div>

                <div class="stats">

                    <div class="stat">
                        <strong>
                          
                            <span id="totalAssetsCount">
                                  <asp:Literal
                                        ID="litTotalAssets"
                                        runat="server"
                                        Text="0">

                                    </asp:Literal>
                            </span>
                        </strong>
                        <span>Total Assets to Checkut</span>
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

            <!-- SCANNED ASSETS -->

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
                            class="btn btn-danger"
                            onclick="clearAllBarcodes()">
                            Clear All
                        </button>

                    </div>
                </div>

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
                                <th>Action</th>
                            </tr>
                        </thead>

                        <tbody id="assetTableBody"></tbody>

                    </table>

                </div>

                <div id="emptyMessage" class="empty">
                    No assets scanned yet.
                </div>

            </div>

            <!-- BULK BATCH -->

            <div class="card">

                <h2 class="section-title">Bulk Batch Transactions
                </h2>

                <p class="description">
                    Select assets and configure their checkout destination.
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

            <div class="batch-footer-content">

                <div class="batch-footer-info">

                    <span class="batch-footer-title">Bulk Asset Transactions
                    </span>

                    <span class="batch-footer-subtitle">
                        <strong id="footerSelectedCount">0</strong>
                        assets selected for checkout
                    </span>

                </div>

                <div class="batch-footer-actions">

                    <button type="button"
                        class="btn checkout-button"
                        onclick="openCheckoutModal()">
                        Checkout
                    </button>

                    <button type="button"
                        class="btn export-button"
                        onclick="exportSelectedCSV()">
                        Export Batch CSV
                    </button>

                </div>

            </div>

        </div>




    <!-- CHECKOUT MODAL -->

    <div id="checkoutModal"
        class="checkout-overlay"
        role="dialog"
        aria-modal="true"
        aria-labelledby="checkoutModalTitle"
        aria-hidden="true">

        <div class="checkout-modal">

            <!-- MODAL HEADER -->

            <div class="modal-header">

                <div class="modal-heading">

                    <div class="modal-icon">↗</div>

                    <div>
                        <h2 id="checkoutModalTitle">Asset Checkout
                        </h2>
                        <p>
                            Configure your bulk asset transaction
                        </p>
                    </div>

                </div>

                <button type="button"
                    class="modal-close"
                    aria-label="Close checkout"
                    onclick="closeCheckoutModal()">
                    &times;
                </button>

            </div>

            <!-- SCROLLABLE MODAL BODY -->

            <div class="modal-body">

                <div class="asset-summary">

                    <span>Selected Assets for Checkout
                    </span>

                    <strong id="checkoutAssetCount">0</strong>

                </div>

                <!-- STEP 1 -->

                <div class="step-heading">
                    <span class="step-number">01</span>
                    Choose Transaction Type
                </div>

                <div class="type-grid">

                    <!-- INTERNAL -->

                    <label class="type-card active"
                        id="internalCard">

                        <input type="radio"
                            name="checkoutType"
                            value="Internal"
                            checked="checked"
                            onchange="changeCheckoutType()" />

                        <span class="type-icon">⌂</span>

                        <span class="type-name">Internal
                        </span>

                        <span class="type-desc">Transfer within the organization
                        </span>

                    </label>

                    <!-- EXTERNAL -->

                    <label class="type-card"
                        id="externalCard">

                        <input type="radio"
                            name="checkoutType"
                            value="External"
                            onchange="changeCheckoutType()" />

                        <span class="type-icon">↗</span>

                        <span class="type-name">External
                        </span>

                        <span class="type-desc">Transfer outside the organization
                        </span>

                    </label>

                </div>

                <!-- INTERNAL CHECKOUT TYPE -->

                <div id="internalSection" class="type-section">

                    <div class="step-heading">
                        <span class="step-number">02</span>
                        Internal Checkout Type
                    </div>

                    <label class="field-label"
                        for="internalCheckoutType">
                        Checkout To
                    </label>

                    <select id="internalCheckoutType"
                        class="checkout-select"
                        onchange="updateCheckoutPreview()">

                        <option value="Location">Location</option>
                      <%--  <option value="User">User</option>
                        <option value="Asset">Asset</option>--%>

                    </select>

                </div>

                <!-- EXTERNAL CHECKOUT TYPE -->

                <div id="externalSection"
                    class="type-section"
                    style="display: none;">

                    <div class="step-heading">
                        <span class="step-number">02</span>
                        External Checkout Type
                    </div>

                    <label class="field-label"
                        for="externalCheckoutType">
                        Checkout To
                    </label>

                    <select id="externalCheckoutType"
                        class="checkout-select"
                        onchange="updateCheckoutPreview()">

                        <option value="Supplier">Supplier</option>
                        <option value="Company">Company</option>

                    </select>

                </div>

                <!-- INTERNAL FORM -->

                <div id="internalFields"
                    class="checkout-form-panel">

                    <h3 id="internalFormTitle"
                        class="checkout-form-title">Location Checkout Details
                    </h3>

                    <!-- LOCATION -->

                    <div id="locationField" class="form-field">

                        <label class="field-label"
                            for="checkoutLocation">
                            Select Location *
                        </label>


                          <asp:DropDownList
                                ID="checkoutLocation"
                                runat="server"
                                ClientIDMode="Static"
                                CssClass="checkout-select"
                            >

                        </asp:DropDownList>

                    </div>

                    <!-- USER -->

                    <div id="userField"
                        class="form-field"
                        style="display: none;">

                        <label class="field-label"
                            for="checkoutUser">
                            Select User *
                        </label>

                        <select id="checkoutUser"
                            class="checkout-select">

                            <option value="">-- Select User --
                            </option>

                            <option value="1">John Silva</option>
                            <option value="U2">Nimal Perera</option>
                            <option value="3">Sarah Fernando</option>
                            <option value="4">Kamal Jayasinghe</option>

                        </select>

                    </div>

                    <!-- ASSET -->

                    <div id="assetField"
                        class="form-field"
                        style="display: none;">

                        <label class="field-label"
                            for="checkoutAsset">
                            Search and Select Asset *
                        </label>

                        <select id="checkoutAsset"
                            placeholder="Search assets...">

                            <option value="">Search an asset...</option>
                            <option value="1">AST001 - Dell Latitude Laptop
                            </option>
                            <option value="2">AST002 - HP LaserJet Printer
                            </option>
                            <option value="3">AST003 - Cisco Network Switch
                            </option>
                            <option value="4">AST004 - Dell PowerEdge Server
                            </option>
                            <option value="5">AST005 - Samsung Monitor
                            </option>
                            <option value="6">AST006 - Lenovo Desktop PC
                            </option>

                        </select>

                        <span class="field-hint">Search by asset ID or name.
                        </span>

                    </div>

                    <!-- INTERNAL DATES -->

                    <div class="form-grid">

                       

                        <div class="form-field">

                            <label class="field-label"
                                for="expectedCheckinDate">
                                Expected Check-in Date *
                            </label>

                            <input id="expectedCheckinDate"
                                class="checkout-input"
                                type="date" />

                        </div>

                    </div>

                    <div class="form-field">

                        <label class="field-label"
                            for="checkoutNote">
                            Note
                        </label>

                        <textarea id="checkoutNote"
                            class="checkout-input checkout-note"
                            maxlength="2000"
                            placeholder="Enter checkout notes..."></textarea>

                    </div>

                    <div id="checkoutValidation"
                        class="validation-error"
                        role="alert">
                    </div>

                </div>

                <!-- EXTERNAL FORM -->

                <div id="externalFields"
                    class="checkout-form-panel"
                    style="display: none;">

                    <h3 id="externalFormTitle"
                        class="checkout-form-title">Supplier Checkout Details
                    </h3>

                    <!-- EXTERNAL SUPPLIER -->

                    <div id="externalSupplierFields">                     

                        <div class="form-field">

                            <label class="field-label"
                                for="externalSupplier">
                                Select Supplier *
                            </label>

<%--                            <select id="externalSupplier"
                                class="checkout-select">

                                <option value="">-- Select Supplier --
                                </option>

                                <option value="SUP001">Dell Technologies</option>
                                <option value="SUP002">HP Supplier</option>
                                <option value="SUP003">ABC Technologies</option>
                                <option value="SUP004">Lanka IT Solutions</option>

                            </select>--%>

                                  <asp:DropDownList
                                    ID="externalSupplier"
                                    runat="server"
                                    ClientIDMode="Static"
                                    CssClass="checkout-select"
                                   >

                                 </asp:DropDownList>

                        </div>

                    </div>

                    <!-- EXTERNAL COMPANY -->

                    <div id="externalCompanyFields"
                        style="display: none;">

                        <div class="form-field">

                            <label class="field-label"
                                for="externalCompany">
                                Select Company *
                            </label>

                       
                            <asp:DropDownList
                                ID="externalCompany"
                                runat="server"
                                ClientIDMode="Static"
                                CssClass="checkout-select"
                                >

                            </asp:DropDownList>

                        </div>

                    </div>

                    <!-- RETURN TYPE -->

                  

                    <div id="permanentInfo"
                        class="permanent-info">
                        Permanent checkout selected. An expected
                    check-in date is not required.
                    </div>

                    <!-- EXTERNAL DATES -->

                    <div class="form-grid">

                        

                        <div id="externalExpectedDateField"
                            class="form-field">

                            <label class="field-label"
                                for="externalExpectedCheckin">
                                Expected Check-in Date *
                            </label>

                            <input id="externalExpectedCheckin"
                                class="checkout-input"
                                type="date" />

                        </div>

                    </div>

                    <!-- EXTERNAL NOTES -->

                    <div class="form-field">

                        <label class="field-label"
                            for="externalNotes">
                            Notes
                        </label>

                        <textarea id="externalNotes"
                            class="checkout-input checkout-note"
                            maxlength="2000"
                            placeholder="Enter external checkout notes..."></textarea>

                    </div>

                    <div id="externalValidation"
                        class="validation-error"
                        role="alert">
                    </div>

                </div>

            </div>

            <!-- FIXED MODAL FOOTER -->

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
                    Continue
                </button>

            </div>

        </div>

    </div>

        </form>

</body>
</html>
