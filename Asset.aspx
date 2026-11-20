<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="Asset.aspx.cs"
    Inherits="Asset_Management.Asset" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Assets | Asset Management System</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="Vendor/fonts/inter/inter.css" />
    <link rel="stylesheet" href="../Style/Header.css" />

    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: 'Inter', Arial, sans-serif;
            background: #f4f8ff;
            color: #1e293b;
        }

        /* Page width and table card only. Header.css is unchanged. */
        .container { width: 100%; max-width: none; margin: 24px auto; padding: 0 20px 25px; }
        .asset-card {
            width: 100%; background: #fff; border: 1px solid #dbe7f5;
            border-radius: 14px; box-shadow: 0 5px 24px rgba(27,75,145,.08);
            overflow: hidden;
        }

        /* Search and table actions */
        .asset-toolbar {
            display: flex; align-items: center; flex-wrap: wrap; gap: 12px;
            padding: 16px 20px; background: #fff; border-bottom: 1px solid #e2eaf5;
        }
        .asset-search-box {
            width: 340px; max-width: 100%; height: 42px; padding: 0 15px;
            font: 500 13px 'Inter',Arial,sans-serif; color: #1e293b;
            background: #f8fbff; border: 1px solid #cfddf0;
            border-radius: 9px; outline: none; transition: .2s;
        }
        .asset-search-box:focus {
            background: #fff; border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37,99,235,.11);
        }
        .asset-search-status { font-size: 12px; color: #64748b; }
        .asset-toolbar-spacer { flex: 1; }
        .asset-action-button {
            height: 40px; padding: 0 15px; display: inline-flex;
            align-items: center; justify-content: center; gap: 8px;
            background: #fff; color: #1e40af; border: 1px solid #cbdcf4;
            border-radius: 9px; font: 600 12px 'Inter',Arial,sans-serif;
            cursor: pointer; transition: .2s; white-space: nowrap;
        }
        .asset-action-button:hover { background: #eef5ff; border-color: #94b9ef; }
        .asset-action-button.primary { background: #2563eb; border-color: #2563eb; color: #fff; }
        .asset-action-button.primary:hover { background: #1d4ed8; }
        .asset-toolbar-info { color: #64748b; font-size: 12px; font-weight: 500; }

        /* Scrollable full-width table */
        .asset-table-wrapper {
            position: relative; width: 100%; min-height: 240px;
            max-height: calc(100vh - 270px);
            overflow: auto; overscroll-behavior: contain;
            scrollbar-width: thin; scrollbar-color: #b7cbea #f1f5f9;
        }
        .asset-table-wrapper::-webkit-scrollbar { width: 9px; height: 9px; }
        .asset-table-wrapper::-webkit-scrollbar-track { background: #f1f5f9; }
        .asset-table-wrapper::-webkit-scrollbar-thumb { background: #b7cbea; border-radius: 8px; }
        .asset-table-wrapper::-webkit-scrollbar-thumb:hover { background: #7ba5df; }
        .asset-table {
            width: max-content; min-width: 100%; border-collapse: separate;
            border-spacing: 0; table-layout: auto; white-space: nowrap;
            background: #fff; color: #334155; font-size: 13px;
        }
        .asset-table thead th {
            position: sticky; top: 0; z-index: 3;
            padding: 10px 14px; background: #eaf2ff;
            color: #1e40af; border-right: 1px solid #dce8f8;
            border-bottom: 2px solid #c7dbf8;
            font-size: 12px; font-weight: 700;
            text-align: left; vertical-align: middle;
        }
        .asset-table thead th:first-child {
            left: 0; z-index: 5; background: #dceaff;
            border-right: 2px solid #bfd5f5;
        }
        .asset-table thead th.asset-sort-selected { background: #d8eaff; }
        .asset-table thead th:first-child.asset-sort-selected { background: #cbdfff; }
        .asset-heading-flex { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
        .asset-heading-label { line-height: 1.3; white-space: nowrap; }
        .asset-sort-controls { display: inline-flex; align-items: center; gap: 3px; flex-shrink: 0; }
        .asset-sort-arrow {
            display: inline-flex; align-items: center; justify-content: center;
            width: 24px; height: 25px; padding: 0;
            border: 1px solid #d0e1fa; border-radius: 5px;
            background: #fff; color: #64748b;
            font-size: 11px; font-weight: 700;
            cursor: pointer; transition: .15s ease;
        }
        .asset-sort-arrow:hover { color: #1d4ed8; border-color: #93b4e6; background: #f5f9ff; }
        .asset-sort-arrow.is-active,
        .asset-sort-arrow.is-active:hover {
            color: #fff; background: #2563eb; border-color: #2563eb;
            box-shadow: 0 2px 6px rgba(37,99,235,.25);
        }
        .asset-sort-arrow:focus-visible,
        .asset-action-button:focus-visible,
        .asset-page-button:focus-visible,
        .asset-sidebar button:focus-visible,
        .asset-sidebar input:focus-visible {
            outline: 3px solid rgba(37,99,235,.35); outline-offset: 2px;
        }
        .asset-table tbody td {
            padding: 13px 16px; background: #fff;
            border-right: 1px solid #f1f5f9;
            border-bottom: 1px solid #edf2f8;
            font-size: 13px; font-weight: 400; vertical-align: middle;
        }
        .asset-table tbody tr.asset-row-alt td { background: #f8fbff; }
        .asset-table tbody tr:hover td { background: #eaf3ff; }
        .asset-table tbody tr:not(.pager) > td:first-child {
            position: sticky; left: 0; z-index: 2;
            color: #2563eb; font-weight: 700; text-align: center;
            border-right: 2px solid #e2eaf5;
        }
        .asset-table tbody tr > td:nth-child(2) { color: #0f3477; font-weight: 600; }
        .asset-table tbody tr > td:nth-child(3) { color: #1d4ed8; font-weight: 600; }
        .asset-table thead th[hidden], .asset-table tbody td[hidden] { display: none !important; }
        .asset-table tbody tr[hidden] { display: none !important; }
        .asset-table tbody tr:not(.pager) > td[colspan] {
            padding: 35px 18px; text-align: center; color: #64748b;
        }
        .asset-no-rows { padding: 35px 18px; color: #64748b; text-align: center; font-size: 13px; }
        .asset-no-rows[hidden] { display: none; }
        .error-message { display: block; color: #b91c1c; font-size: 13px; }
        .error-message:not(:empty) { padding: 12px 18px; }

        /* Client-side pagination -- operates after sorting ALL loaded rows */
        .asset-footer {
            display: flex; align-items: center; flex-wrap: wrap; gap: 12px;
            justify-content: space-between; padding: 14px 20px;
            background: #fff; border-top: 1px solid #e2eaf5;
        }
        .asset-row-count { font-size: 12px; color: #64748b; font-weight: 500; }
        .asset-footer-controls { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
        .asset-page-size-wrap { display: flex; align-items: center; gap: 7px; color: #64748b; font-size: 12px; }
        .asset-page-size {
            height: 34px; padding: 0 7px; border: 1px solid #d6e4f5;
            border-radius: 7px; background: #fff; color: #334155; font-family: inherit;
        }
        .asset-pagination { display: flex; align-items: center; flex-wrap: wrap; gap: 5px; }
        .asset-page-button {
            min-width: 34px; height: 34px; padding: 0 10px;
            border: 1px solid #d6e4f5; border-radius: 7px;
            background: #f7faff; color: #2563eb;
            font: 600 12px 'Inter',Arial,sans-serif; cursor: pointer;
        }
        .asset-page-button:hover:not(:disabled) { background: #e8f2ff; }
        .asset-page-button.is-current { color: #fff; background: #2563eb; border-color: #2563eb; }
        .asset-page-button:disabled { opacity: .4; cursor: not-allowed; }
        .asset-page-ellipsis { padding: 0 2px; color: #94a3b8; }

        /* Column visibility sidebar */
        .asset-sidebar-backdrop {
            position: fixed; inset: 0; z-index: 9998;
            background: rgba(15,23,42,.43); opacity: 0;
            visibility: hidden; pointer-events: none;
            transition: opacity .25s ease, visibility .25s ease;
        }
        .asset-sidebar-backdrop.is-open { opacity: 1; visibility: visible; pointer-events: auto; }
        .asset-sidebar {
            position: fixed; top: 0; right: 0; z-index: 9999;
            width: min(390px,100vw); height: 100dvh;
            display: flex; flex-direction: column;
            background: #fff; box-shadow: -15px 0 42px rgba(15,23,42,.19);
            transform: translateX(102%); visibility: hidden;
            transition: transform .26s ease, visibility .26s ease;
        }
        .asset-sidebar.is-open { transform: translateX(0); visibility: visible; }
        body.asset-sidebar-open { overflow: hidden; }
        .asset-sidebar-head {
            display: flex; align-items: flex-start; justify-content: space-between;
            gap: 12px; padding: 24px 22px 18px; border-bottom: 1px solid #e2e8f0;
        }
        .asset-sidebar-kicker { color: #2563eb; font-weight: 700; font-size: 10px; letter-spacing: 1.1px; }
        .asset-sidebar-title { margin: 6px 0; color: #102a56; font-size: 20px; font-weight: 750; }
        .asset-sidebar-subtitle { margin: 0; color: #64748b; line-height: 1.55; font-size: 12px; }
        .asset-sidebar-close {
            width: 34px; height: 34px; flex-shrink: 0;
            border: 1px solid #e2e8f0; border-radius: 8px;
            background: #f8fafc; color: #475569;
            font-size: 22px; cursor: pointer;
        }
        .asset-sidebar-tools { padding: 18px 22px 14px; border-bottom: 1px solid #edf2f7; }
        .asset-column-search {
            width: 100%; height: 39px; padding: 0 12px;
            border: 1px solid #d5e1f0; border-radius: 8px;
            font: 500 12px 'Inter',Arial,sans-serif; outline: none;
        }
        .asset-column-search:focus { border-color: #2563eb; }
        .asset-column-presets { display: flex; gap: 8px; margin-top: 12px; }
        .asset-preset-button {
            flex: 1; min-height: 34px; background: #f0f6ff;
            border: 1px solid #d8e7fc; color: #2459a6;
            border-radius: 7px; font: 650 12px 'Inter',Arial,sans-serif;
            cursor: pointer;
        }
        .asset-preset-button:hover { background: #dfeeff; }
        .asset-sidebar-list-head {
            display: flex; justify-content: space-between; align-items: center;
            padding: 13px 22px; font-size: 12px; color: #64748b; font-weight: 600;
        }
        .asset-column-options { flex: 1; overflow-y: auto; padding: 0 14px 15px; }
        .asset-column-option {
            display: flex; align-items: center; gap: 12px;
            margin: 4px 0; padding: 12px 10px;
            border: 1px solid transparent; border-radius: 9px;
            color: #334155; font-size: 13px; font-weight: 550;
            cursor: pointer; transition: background .15s ease;
        }
        .asset-column-option:hover { background: #f3f8ff; border-color: #e3eefc; }
        .asset-column-option input { width: 17px; height: 17px; accent-color: #2563eb; cursor: pointer; }
        .asset-column-option span { flex: 1; }
        .asset-sidebar-bottom {
            display: flex; align-items: center; justify-content: space-between; gap: 10px;
            border-top: 1px solid #e2e8f0; padding: 16px 22px;
        }
        .asset-sidebar-note { font-size: 11px; color: #64748b; }
        @media (max-width: 700px) {
            .container { padding: 0 10px 18px; }
            .asset-toolbar { padding: 12px; }
            .asset-toolbar-spacer { display: none; }
            .asset-search-box { width: 100%; }
            .asset-toolbar-info { width: 100%; }
            .asset-table-wrapper { max-height: calc(100vh - 320px); }
            .asset-table thead th { padding: 10px; }
            .asset-table tbody td { padding: 11px 12px; }
            .asset-footer { padding: 12px; }
            .asset-footer-controls { width: 100%; justify-content: space-between; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">

            <!-- Existing page heading and Home button (heading CSS unchanged) -->
            <div class="transfer-page-header">
                <a href='<%= ResolveUrl("~/Home.aspx") %>'
                   class="transfer-home-btn" title="Home" aria-label="Go to Home">
                    <svg xmlns="http://www.w3.org/2000/svg" width="23" height="23"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor"
                         stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="m3 10 9-7 9 7" />
                        <path d="M5 9v12h14V9" />
                        <path d="M9 21v-7h6v7" />
                    </svg>
                </a>
                <div class="transfer-page-heading">
                    <h2 class="page-title">Assets Master</h2>
                    <p class="description">View All the Assets in the Record</p>
                </div>
            </div>

            <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePartialRendering="true" />

            <div class="asset-card">
                <div class="asset-toolbar">
                    <asp:TextBox ID="txtSearch" runat="server"
                        CssClass="asset-search-box"
                        placeholder="Search assets, tags, serials..."
                        autocomplete="off" oninput="searchAssets()" />

                    <span id="searchStatus" class="asset-search-status"></span>

                    <!-- Keep this for the existing C# search handler. -->
                    <asp:Button ID="btnSearch" runat="server" Text="Search"
                        OnClick="btnSearch_Click" Style="display: none;" />

                    <div class="asset-toolbar-spacer"></div>

                    <span id="assetToolbarInfo" class="asset-toolbar-info"></span>

                    <button type="button" class="asset-action-button" onclick="resetAssetSort()"
                            title="Restore original row order">
                        Clear sorting
                    </button>
                    <button type="button" id="assetOpenColumns" class="asset-action-button primary"
                            onclick="openColumnSidebar()" aria-haspopup="dialog" aria-expanded="false">
                        &#9776; &nbsp; Columns
                    </button>
                
                    <asp:HiddenField 
                        ID="hfVisibleColumns" runat="server"/>

                    <asp:Button 
                        ID="btnExportExcel"
                        runat="server"
                        Text="Export Excel"
                        CssClass="asset-action-button primary"
                        OnClientClick="return prepareAssetExport();"
                        OnClick="btnExportExcel_Click"
                        />
                </div>

                <asp:UpdatePanel ID="updAssests" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:Label ID="lblMessage" runat="server" CssClass="error-message" />

                        <div class="asset-table-wrapper" id="assetTableWrapper">
                            <asp:GridView ID="gvAssets" runat="server"
                                AutoGenerateColumns="False"
                                CssClass="asset-table"
                                GridLines="None"
                                AllowPaging="False"
                                ShowHeaderWhenEmpty="True"
                                EmptyDataText="No assets found.">

                              
                                <Columns>
                                    <asp:TemplateField HeaderText="ID">
                                        <ItemTemplate><%# Container.DataItemIndex + 1 %></ItemTemplate>
                                    </asp:TemplateField>
                                    <asp:BoundField DataField="AssetName" HeaderText="Asset Name" NullDisplayText="-" />
                                    <asp:BoundField DataField="barcodeId" HeaderText="BarCode ID" NullDisplayText="-" />
                                    <asp:BoundField DataField="Company" HeaderText="Company" NullDisplayText="-" />
                                    <asp:BoundField DataField="SubCategory" HeaderText="Sub Category" NullDisplayText="-" />
                                    <asp:BoundField DataField="MachineNo" HeaderText="Machine Number" NullDisplayText="" />
                                    <asp:BoundField DataField="Currency" HeaderText="Currency" NullDisplayText="-" />
                                    <asp:BoundField DataField="Model" HeaderText="Model" NullDisplayText="-" />
                                    <asp:BoundField DataField="Model_No" HeaderText="Model Number" ConvertEmptyStringToNull="True" />
                                    <asp:BoundField DataField="Manufacturer" HeaderText="Manufacturer" NullDisplayText="-" />
                                    <asp:BoundField DataField="Serial" HeaderText="Serial" NullDisplayText="-" />
                                    <asp:BoundField DataField="Location" HeaderText="Current Location" NullDisplayText="-" />
                                    <asp:BoundField DataField="DefaultLocation" HeaderText="Default Location" NullDisplayText="-" />
                                    <asp:BoundField DataField="Status" HeaderText="Status" NullDisplayText="-" />
                                    <asp:BoundField DataField="Cost" HeaderText="Cost" NullDisplayText="-" />
                                    <asp:BoundField DataField="PurchasedOn" HeaderText="PurchasedDate" NullDisplayText="-" />
                                    <asp:BoundField DataField="EOL" HeaderText="EOL" NullDisplayText="-" />
                                    <asp:BoundField DataField="Warranty" HeaderText="Warranty" NullDisplayText="-" />
                                    <asp:BoundField DataField="WarrantyExpiredDate" HeaderText="Warranty Expired" NullDisplayText="-" />
                                </Columns>

                            </asp:GridView>
                            <div id="assetNoRows" class="asset-no-rows" hidden>No assets to display.</div>
                        </div>
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="btnSearch" EventName="Click" />
                    </Triggers>
                </asp:UpdatePanel>

                <!-- This is CLIENT pagination, not GridView pagination. -->
                <div class="asset-footer">
                    <span id="assetRowCount" class="asset-row-count">Loading assets...</span>
                    <div class="asset-footer-controls">
                        <label class="asset-page-size-wrap" for="assetPageSize">
                            Rows per page
                            <select id="assetPageSize" class="asset-page-size" onchange="setAssetPageSize(this.value)">
                                <option value="25">25</option>
                                <option value="50" selected="selected">50</option>
                                <option value="100">100</option>
                                <option value="250">250</option>
                                <option value="0">All</option>
                            </select>
                        </label>
                        <nav id="assetPagination" class="asset-pagination" aria-label="Asset table pages"></nav>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right-side column selector -->
        <div id="assetSidebarBackdrop" class="asset-sidebar-backdrop"
             onclick="closeColumnSidebar()" aria-hidden="true"></div>

        <aside id="assetSidebar" class="asset-sidebar" role="dialog" aria-modal="true"
               aria-hidden="true" aria-labelledby="assetColumnTitle" tabindex="-1">
            <div class="asset-sidebar-head">
                <div>
                    <div class="asset-sidebar-kicker">CUSTOMIZE VIEW</div>
                    <h3 class="asset-sidebar-title" id="assetColumnTitle">Visible columns</h3>
                    <p class="asset-sidebar-subtitle">Choose which asset details are shown in your table. Preferences are saved in this browser.</p>
                </div>
                <button type="button" class="asset-sidebar-close" onclick="closeColumnSidebar()"
                        aria-label="Close column settings">&times;</button>
            </div>
            <div class="asset-sidebar-tools">
                <input type="search" id="assetColumnSearch" class="asset-column-search"
                       placeholder="Find a column..." aria-label="Find a column"
                       oninput="renderAssetColumnOptions()" />
                <div class="asset-column-presets">
                    <button type="button" class="asset-preset-button" onclick="showEssentialColumns()">Essentials only</button>
                    <button type="button" class="asset-preset-button" onclick="showAllAssetColumns()">Show all</button>
                </div>
            </div>
            <div class="asset-sidebar-list-head">
                <span>TABLE COLUMNS</span>
                <span id="assetVisibleCount">19 of 19 visible</span>
            </div>
            <div id="assetColumnOptions" class="asset-column-options"></div>
            <div class="asset-sidebar-bottom">
                <span class="asset-sidebar-note">Changes apply instantly</span>
                <button type="button" class="asset-action-button primary" onclick="closeColumnSidebar()">Done</button>
            </div>
        </aside>
    </form>

    <script type="text/javascript">
        // GridView server paging must be OFF. All bound rows must reach the browser.
        // JavaScript sorts the complete loaded set BEFORE deciding which 50 to display.

        var assetSearchTimer;
        var lastAssetSearch = "";
        var assetPreferencesKey = "assets-master-table-settings-v1";
        var savedAssetPreferences = readAssetPreferences();
        var assetState = {
            table: null,
            tbody: null,
            records: [],
            columns: [],
            sortLabel: savedAssetPreferences.sortLabel || "",
            sortDirection: savedAssetPreferences.sortDirection || "asc",
            page: 1,
            pageSize: [0, 25, 50, 100, 250].indexOf(Number(savedAssetPreferences.pageSize)) >= 0
                ? Number(savedAssetPreferences.pageSize) : 50,
            savedVisibility: savedAssetPreferences.visibility || {},
            lastFocusedElement: null
        };
        var assetTextCollator = new Intl.Collator('en', { sensitivity: 'base', numeric: true });

        function readAssetPreferences() {
            try { return JSON.parse(localStorage.getItem(assetPreferencesKey)) || {}; }
            catch (e) { return {}; }
        }

        function saveAssetPreferences() {
            var visibility = {};
            assetState.columns.forEach(function (column) {
                visibility[column.label] = column.visible;
            });
            assetState.savedVisibility = visibility;
            try {
                localStorage.setItem(assetPreferencesKey, JSON.stringify({
                    visibility: visibility,
                    sortLabel: assetState.sortLabel,
                    sortDirection: assetState.sortDirection,
                    pageSize: assetState.pageSize
                }));
            } catch (e) { /* Browser storage may be disabled. */ }
        }

        function initializeAssetTable() {
            var table = document.getElementById('<%= gvAssets.ClientID %>');
            var noRows = document.getElementById('assetNoRows');
            if (!table || table.dataset.assetInitialized === '1') { return; }

            var headerRow = Array.prototype.find.call(table.rows, function (row) {
                return row.querySelector('th') !== null;
            });
            if (!headerRow) {
                assetState.records = [];
                if (noRows) { noRows.hidden = true; }
                updateAssetFooter();
                return;
            }

            // GridView emits TH tags but not always an actual THEAD.
            // Move its header into a THEAD so CSS sticky headers are reliable.
            if (!table.tHead) {
                var thead = table.createTHead();
                thead.appendChild(headerRow);
            }

            assetState.table = table;
            assetState.tbody = table.tBodies.length ? table.tBodies[0] : table.createTBody();
            assetState.columns = Array.prototype.map.call(headerRow.cells, function (th, index) {
                var label = th.textContent.trim();
                return {
                    index: index,
                    label: label,
                    th: th,
                    visible: assetState.savedVisibility[label] !== false
                };
            });

            var columnCount = assetState.columns.length;
            assetState.records = Array.prototype.filter.call(assetState.tbody.rows, function (row) {
                return row.cells.length === columnCount &&
                    !row.classList.contains('pager') &&
                    Array.prototype.every.call(row.cells, function (cell) { return cell.colSpan === 1; });
            }).map(function (row, index) {
                return {
                    row: row,
                    originalIndex: index,
                    values: Array.prototype.map.call(row.cells, function (cell) {
                        return cell.textContent.replace(/\s+/g, ' ').trim();
                    })
                };
            });

            if (!assetState.columns.some(function (col) { return col.visible; })) {
                assetState.columns[0].visible = true;
            }

            addAssetSortButtons();
            applyAssetColumnVisibility();
            document.getElementById('assetPageSize').value = String(assetState.pageSize);
            sortAllAssetRows(false);
            renderAssetColumnOptions();
            table.dataset.assetInitialized = '1';
        }

        function addAssetSortButtons() {
            assetState.columns.forEach(function (column) {
                var th = column.th;
                th.textContent = '';

                var wrapper = document.createElement('div');
                wrapper.className = 'asset-heading-flex';

                var label = document.createElement('span');
                label.className = 'asset-heading-label';
                label.textContent = column.label;

                var controls = document.createElement('span');
                controls.className = 'asset-sort-controls';

                [['asc', '▲', 'ascending'], ['desc', '▼', 'descending']].forEach(function (config) {
                    var button = document.createElement('button');
                    button.type = 'button';
                    button.className = 'asset-sort-arrow';
                    button.textContent = config[1];
                    button.title = 'Sort ' + column.label + ' ' + config[2];
                    button.setAttribute('aria-label', button.title);
                    button.setAttribute('aria-pressed', 'false');
                    button.dataset.direction = config[0];
                    button.addEventListener('click', function () {
                        sortAssetColumn(column.label, config[0]);
                    });
                    controls.appendChild(button);
                });

                wrapper.appendChild(label);
                wrapper.appendChild(controls);
                th.appendChild(wrapper);
            });
        }

        function sortAssetColumn(label, direction) {
            assetState.sortLabel = label;
            assetState.sortDirection = direction;
            assetState.page = 1;
            sortAllAssetRows(true);
            saveAssetPreferences();
        }

        function resetAssetSort() {
            assetState.sortLabel = '';
            assetState.sortDirection = 'asc';
            assetState.page = 1;
            sortAllAssetRows(true);
            saveAssetPreferences();
        }

        function numericAssetValue(value) {
            var stripped = (value || '').replace(/,/g, '').replace(/[^0-9.+\-]/g, '');
            if (!stripped || !/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(stripped)) { return null; }
            var number = Number(stripped);
            return isFinite(number) ? number : null;
        }

        function dateAssetValue(value) {
            var match = (value || '').match(/^(\d{4})[-\/]\s*(\d{1,2})[-\/](\d{1,2})/);
            if (match) { return Date.UTC(+match[1], +match[2] - 1, +match[3]); }
            match = (value || '').match(/^(\d{1,2})[-\/.](\d{1,2})[-\/.](\d{4})/);
            if (match) {
                // Day/month/year for local dates; disambiguate values above 12.
                var first = +match[1], second = +match[2];
                var day = first, month = second;
                if (second > 12 && first <= 12) { day = second; month = first; }
                return Date.UTC(+match[3], month - 1, day);
            }
            var parsed = Date.parse(value);
            return isNaN(parsed) ? null : parsed;
        }

        function compareAssetValues(a, b, index, direction) {
            var textA = (a || '').trim(), textB = (b || '').trim();
            var emptyA = !textA || textA === '-' || /^N\/?A$/i.test(textA);
            var emptyB = !textB || textB === '-' || /^N\/?A$/i.test(textB);
            if (emptyA && emptyB) { return 0; }
            if (emptyA) { return 1; } // Empty values always last.
            if (emptyB) { return -1; }

            var result = 0;
            if ([0, 2, 13, 14, 17].indexOf(index) >= 0) {
                var numA = numericAssetValue(textA), numB = numericAssetValue(textB);
                if (numA !== null && numB !== null) { result = numA - numB; }
                else { result = assetTextCollator.compare(textA, textB); }
            } else if (index === 16) {
                var eolA = numericAssetValue(textA), eolB = numericAssetValue(textB);
                if (eolA !== null && eolB !== null) { result = eolA - eolB; }
                else {
                    var eolDateA = dateAssetValue(textA), eolDateB = dateAssetValue(textB);
                    result = eolDateA !== null && eolDateB !== null
                        ? eolDateA - eolDateB : assetTextCollator.compare(textA, textB);
                }
            } else if ([15, 18].indexOf(index) >= 0) {
                var dateA = dateAssetValue(textA), dateB = dateAssetValue(textB);
                if (dateA !== null && dateB !== null) { result = dateA - dateB; }
                else { result = assetTextCollator.compare(textA, textB); }
            } else {
                result = assetTextCollator.compare(textA, textB);
            }
            return direction === 'desc' ? -result : result;
        }

        function sortAllAssetRows(scrollToTop) {
            if (!assetState.tbody) { return; }
            var columnIndex = assetState.columns.findIndex(function (column) {
                return column.label === assetState.sortLabel;
            });

            assetState.records.sort(function (recordA, recordB) {
                if (columnIndex < 0) { return recordA.originalIndex - recordB.originalIndex; }
                var compared = compareAssetValues(
                    recordA.values[columnIndex], recordB.values[columnIndex],
                    columnIndex, assetState.sortDirection
                );
                return compared || recordA.originalIndex - recordB.originalIndex;
            });

            // Reorder every record, not just the displayed page.
            var fragment = document.createDocumentFragment();
            assetState.records.forEach(function (record) { fragment.appendChild(record.row); });
            assetState.tbody.appendChild(fragment);

            assetState.columns.forEach(function (column) {
                var activeColumn = column.label === assetState.sortLabel;
                column.th.classList.toggle('asset-sort-selected', activeColumn);
                column.th.querySelectorAll('.asset-sort-arrow').forEach(function (button) {
                    var active = activeColumn && button.dataset.direction === assetState.sortDirection;
                    button.classList.toggle('is-active', active);
                    button.setAttribute('aria-pressed', active ? 'true' : 'false');
                });
                column.th.setAttribute('aria-sort', activeColumn
                    ? (assetState.sortDirection === 'asc' ? 'ascending' : 'descending')
                    : 'none');
            });

            showAssetPage(scrollToTop);
        }

        function setAssetPageSize(value) {
            assetState.pageSize = Number(value);
            assetState.page = 1;
            showAssetPage(true);
            saveAssetPreferences();
        }

        function gotoAssetPage(page) {
            assetState.page = page;
            showAssetPage(true);
        }

        function showAssetPage(scrollToTop) {
            var total = assetState.records.length;
            var limit = assetState.pageSize === 0 ? Math.max(total, 1) : assetState.pageSize;
            var pages = Math.max(1, Math.ceil(total / limit));
            assetState.page = Math.min(Math.max(1, assetState.page), pages);
            var start = (assetState.page - 1) * limit;
            var end = Math.min(start + limit, total);

            assetState.records.forEach(function (record, index) {
                var visible = index >= start && index < end;
                record.row.hidden = !visible;
                record.row.classList.toggle('asset-row-alt', visible && (index - start) % 2 === 1);
            });

            var noRows = document.getElementById('assetNoRows');
            if (noRows) {
                var hasGridViewEmptyRow = assetState.tbody &&
                    Array.prototype.some.call(assetState.tbody.rows, function (row) {
                        return row.cells.length === 1 && row.cells[0].colSpan > 1;
                    });
                noRows.hidden = total !== 0 || !!hasGridViewEmptyRow;
            }
            var count = document.getElementById('assetRowCount');
            if (count) {
                count.textContent = total === 0 ? '0 assets' :
                    'Showing ' + (start + 1).toLocaleString() + '–' + end.toLocaleString() +
                    ' of ' + total.toLocaleString() + ' assets';
            }
            updateAssetFooter();
            renderAssetPageButtons(pages);

            if (scrollToTop) {
                var wrapper = document.getElementById('assetTableWrapper');
                if (wrapper) { wrapper.scrollTop = 0; }
            }
        }

        function updateAssetFooter() {
            var info = document.getElementById('assetToolbarInfo');
            if (info) {
                var total = assetState.records.length;
                info.textContent = total.toLocaleString() + ' records loaded';
            }
        }

        function renderAssetPageButtons(totalPages) {
            var nav = document.getElementById('assetPagination');
            if (!nav) { return; }
            nav.textContent = '';

            function addButton(label, page, disabled, current) {
                var button = document.createElement('button');
                button.type = 'button';
                button.className = 'asset-page-button' + (current ? ' is-current' : '');
                button.textContent = label;
                button.disabled = !!disabled;
                if (current) { button.setAttribute('aria-current', 'page'); }
                button.addEventListener('click', function () { gotoAssetPage(page); });
                nav.appendChild(button);
            }

            function addDots() {
                var dots = document.createElement('span');
                dots.className = 'asset-page-ellipsis';
                dots.textContent = '…';
                nav.appendChild(dots);
            }

            addButton('‹', assetState.page - 1, assetState.page <= 1, false);
            var first = Math.max(1, assetState.page - 2);
            var last = Math.min(totalPages, assetState.page + 2);
            if (first > 1) {
                addButton('1', 1, false, assetState.page === 1);
                if (first > 2) { addDots(); }
            }
            for (var page = first; page <= last; page++) {
                addButton(String(page), page, false, page === assetState.page);
            }
            if (last < totalPages) {
                if (last < totalPages - 1) { addDots(); }
                addButton(String(totalPages), totalPages, false, assetState.page === totalPages);
            }
            addButton('›', assetState.page + 1, assetState.page >= totalPages, false);
        }

        function applyAssetColumnVisibility() {
            assetState.columns.forEach(function (column) {
                column.th.hidden = !column.visible;
            });
            assetState.records.forEach(function (record) {
                assetState.columns.forEach(function (column) {
                    if (record.row.cells[column.index]) {
                        record.row.cells[column.index].hidden = !column.visible;
                    }
                });
            });
            var count = document.getElementById('assetVisibleCount');
            if (count) {
                var visible = assetState.columns.filter(function (col) { return col.visible; }).length;
                count.textContent = visible + ' of ' + assetState.columns.length + ' visible';
            }
        }

        function toggleAssetColumn(index, visible) {
            var showing = assetState.columns.filter(function (column) { return column.visible; }).length;
            if (!visible && showing <= 1) { renderAssetColumnOptions(); return; }
            assetState.columns[index].visible = visible;
            applyAssetColumnVisibility();
            saveAssetPreferences();
        }

        function renderAssetColumnOptions() {
            var holder = document.getElementById('assetColumnOptions');
            if (!holder) { return; }
            holder.textContent = '';
            var search = document.getElementById('assetColumnSearch');
            var term = search ? search.value.trim().toLowerCase() : '';
            var matches = 0;

            assetState.columns.forEach(function (column) {
                if (term && column.label.toLowerCase().indexOf(term) < 0) { return; }
                matches++;
                var option = document.createElement('label');
                option.className = 'asset-column-option';
                var checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.checked = column.visible;
                checkbox.addEventListener('change', function () {
                    toggleAssetColumn(column.index, checkbox.checked);
                });
                var title = document.createElement('span');
                title.textContent = column.label;
                option.appendChild(checkbox);
                option.appendChild(title);
                holder.appendChild(option);
            });
            if (!matches) {
                var noMatch = document.createElement('p');
                noMatch.className = 'asset-sidebar-note';
                noMatch.style.padding = '16px 10px';
                noMatch.textContent = 'No columns match that search.';
                holder.appendChild(noMatch);
            }
        }

        function showAllAssetColumns() {
            assetState.columns.forEach(function (column) { column.visible = true; });
            applyAssetColumnVisibility();
            renderAssetColumnOptions();
            saveAssetPreferences();
        }

        function showEssentialColumns() {
            var essentials = [
                'ID', 'Asset Name', 'BarCode ID', 'Company', 'Sub Category',
                'Model', 'Serial', 'Current Location', 'Status', 'Cost'
            ];
            assetState.columns.forEach(function (column) {
                column.visible = essentials.indexOf(column.label) !== -1;
            });
            applyAssetColumnVisibility();
            renderAssetColumnOptions();
            saveAssetPreferences();
        }

        function prepareAssetExport() {
            if (!assetState.columns || assetState.columns.length === 0) {
                alert("Assets columns are not loaded");
                return false;
            }

            var visibleColumns = assetState.columns
                .filter(function (column) {
                    return column.visible === true;
                })
                .map(function (column) {
                    return column.index;
                });

            if (visibleColumns.length === 0) {
                alert("Please select at least one column");
                return false;
            }

            document.getElementById('<%= hfVisibleColumns.ClientID %>').value =
                visibleColumns.join(",");

            return true;
        }

        function openColumnSidebar() {
            assetState.lastFocusedElement = document.activeElement;
            document.getElementById('assetSidebarBackdrop').classList.add('is-open');
            var sidebar = document.getElementById('assetSidebar');
            sidebar.classList.add('is-open');
            sidebar.setAttribute('aria-hidden', 'false');
            document.getElementById('assetOpenColumns').setAttribute('aria-expanded', 'true');
            document.body.classList.add('asset-sidebar-open');
            renderAssetColumnOptions();
            document.getElementById('assetColumnSearch').focus();
        }

        function closeColumnSidebar() {
            document.getElementById('assetSidebarBackdrop').classList.remove('is-open');
            var sidebar = document.getElementById('assetSidebar');
            sidebar.classList.remove('is-open');
            sidebar.setAttribute('aria-hidden', 'true');
            document.getElementById('assetOpenColumns').setAttribute('aria-expanded', 'false');
            document.body.classList.remove('asset-sidebar-open');
            if (assetState.lastFocusedElement && typeof assetState.lastFocusedElement.focus === 'function') {
                assetState.lastFocusedElement.focus();
            }
        }

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' && document.getElementById('assetSidebar').classList.contains('is-open')) {
                closeColumnSidebar();
            }
        });

        // Keep the existing backend search behavior.
        // After the UpdatePanel returns, re-apply the chosen sorting and columns.
        function searchAssets() {
            clearTimeout(assetSearchTimer);
            var box = document.getElementById('<%= txtSearch.ClientID %>');
            var status = document.getElementById('searchStatus');
            var value = box.value;
            status.textContent = 'Typing...';

            assetSearchTimer = setTimeout(function () {
                if (value === lastAssetSearch) { status.textContent = ''; return; }
                lastAssetSearch = value;
                status.textContent = 'Searching...';
                __doPostBack('<%= btnSearch.UniqueID %>', '');
            }, 300);
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeAssetTable);
        } else {
            initializeAssetTable();
        }

        if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                document.getElementById('searchStatus').textContent = '';
                initializeAssetTable();
            });
        }
    </script>
</body>
</html>
