<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="DispatchDashboard.aspx.cs"
    Inherits="Asset_Management.Dispatch.DispatchDashboard" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">

    <script>
        window.addEventListener('error', function (e) {
            var t = e.target || {};
            console.error('[DIAG] ' + (t.src || t.href ? 'RESOURCE FAILED: ' + (t.src || t.href) : 'JS ERROR: ' + e.message + ' @ ' + e.filename + ':' + e.lineno), e);
        }, true);
        window.addEventListener('unhandledrejection', function (e) { console.error('[DIAG] PROMISE ERROR', e.reason); });
        console.log('[DIAG] head reached', performance.now().toFixed(0) + 'ms');
        document.addEventListener('readystatechange', function () { console.log('[DIAG] readyState =', document.readyState); });
        window.addEventListener('beforeunload', function () { console.warn('[DIAG] page is navigating away / reloading'); });
    </script>



    <title>Dispatch Dashboard</title>

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0" />

    <link rel="stylesheet"
          href="<%= ResolveUrl("~/Vendor/fonts/inter/inter.css") %>" />
     <script src="<%= ResolveUrl("~/Vendor/sweetalert2/sweetalert2.all.min.js") %>"></script>

    <link rel="stylesheet" href="<%= ResolveUrl("~/Style/Header.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Style/style.css") %>" />


    <style>
        .status.status-approved {
            padding: 5px 9px;
            background: #dcfce7;
            color: #166534;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
        }

        .status.status-declined {
            padding: 5px 9px;
            background: #fee2e2;
            color: #991b1b;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
        }

        .status.status-pending {
            padding: 5px 9px;
            background: #fef9c3;
            color: #854d0e;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
        }
    </style>
</head>

<body>

<form id="form1" runat="server">

    <div class="grid-container">

        <!-- PAGE HEADER -->

        <div class="transfer-page-header">

            <a href='<%= ResolveUrl("~/Home.aspx") %>'
               class="transfer-home-btn"
               title="Home"
               aria-label="Go to Home">

                <svg xmlns="http://www.w3.org/2000/svg"
                     width="23"
                     height="23"
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

            <div class="transfer-page-heading">

                <h2 class="page-title">
                    Dispatch Note
                </h2>

                <p class="description">
                    View and manage approved dispatch transactions
                </p>

            </div>

        </div>

        <!-- ERROR MESSAGE -->

        <asp:Label
            ID="lblError"
            runat="server"
            CssClass="dispatch-error"
            Visible="false" />

        <!-- DISPATCH GRID -->

        <div class="table-wrapper">

            <asp:GridView
                ID="gvDispatch"
                runat="server"
                AutoGenerateColumns="False"
                CssClass="approval-grid"
                GridLines="None"
                ShowHeader="False"
                OnRowCommand="gvDispatch_RowCommand"
                EmptyDataText="No approved dispatch transactions found.">

                <Columns>

                    <asp:TemplateField>

                        <ItemTemplate>

                            <div class="transaction-card"
                                 data-transfer-source='<%#: Eval("TransferType") %>'>

                                <!-- HEADER -->

                                <div class="transaction-header">

                                    <div class="transaction-title">

                                        <button
                                            type="button"
                                            class="btn btn-toggle"
                                            aria-expanded="false"
                                            aria-label="Show asset details"
                                            onclick="toggleAssets(this)">
                                            +
                                        </button>

                                        <span class="transaction-tag">
                                            <%#: Eval("TransactionTag") %>
                                        </span>

                                        <!-- COMPANY / SUPPLIER -->

                                        <span
                                            class='transfer-source <%# Convert.ToString(Eval("TransferType")) == "Company" ? "transfer-company" : "transfer-supplier" %>'>

                                            <%#: Eval("TransferType") %>

                                        </span>

                                        <span class="asset-count">
                                            <%#: Eval("AssetCount") %>
                                            Assets
                                        </span>

                                        <span class='status <%# GetStatusClass(Eval("StatusName")) %>' >
                                            <%#: Eval("StatusName") %>
                                          
                                        </span>

                                    </div>

                                    <asp:PlaceHolder runat="server" Visible='<%# Convert.ToBoolean(Eval("CanView")) %>'>
                                        <div class="actions">
                                           <asp:Button 
                                               ID="btnCreateDispatch"
                                               runat="server"
                                               Text="Create Dispatch"
                                               CssClass="btn btn-approve"
                                               CommandName="CreateDispatch"
                                               CommandArgument='<%# Eval("TransferType") + "|" + Eval("TransactionTag") %>'
                                               />
                                        </div>
                                    </asp:PlaceHolder>

                                </div>

                                <!-- TRANSACTION INFORMATION -->

                                <div class="transaction-meta">

                                    <span>
                                        Destination:
                                        <strong>
                                            <%#: Eval("Destination") %>
                                        </strong>
                                    </span>

                                    <span>
                                        Created By:
                                        <strong>
                                            <%#: Eval("UserID") %>
                                        </strong>
                                    </span>

                                    <span>
                                        Created On:
                                        <strong>
                                            <%# Eval("CreatedAT") %>
                                        </strong>
                                    </span>

                                    <span>
                                        <%#: Eval("StatusDateLabel") %>
                                        <strong>
                                            <%#: Eval("ApprovedOn") %>
                                        </strong>
                                    </span>

                                    <span>
                                        <%# Eval("StatusNoteLabel") %>
                                        <strong>
                                            <%#: Eval("ApproveNote") %>
                                        </strong>
                                    </span>

                                    <span>
                                        Comment:
                                        <strong>
                                            <%#: Eval("Comment") %>
                                        </strong>
                                    </span>

                                </div>

                                <!-- EXPANDABLE ASSET DETAILS -->

                                <div class="asset-details">

                                    <table class="child-table">

                                        <thead>
                                            <tr>
                                                <th>#</th>
                                                <th>Asset Name</th>
                                                <th>Serial</th>
                                                <th>Machine No</th>
                                            </tr>
                                        </thead>

                                        <tbody>

                                            <asp:Repeater
                                                ID="rptAssets"
                                                runat="server"
                                                DataSource='<%# Eval("Assets") %>'>

                                                <ItemTemplate>

                                                    <tr>

                                                        <td>
                                                            <%# Container.ItemIndex + 1 %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("AssetName") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("Serial") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("MachineNo") %>
                                                        </td>

                                                    </tr>

                                                </ItemTemplate>

                                            </asp:Repeater>

                                        </tbody>

                                    </table>

                                </div>

                            </div>

                        </ItemTemplate>

                    </asp:TemplateField>

                </Columns>

                <EmptyDataRowStyle CssClass="empty-row" />

            </asp:GridView>

        </div>

    </div>

</form>

<!-- EXPAND / COLLAPSE ONLY -->

<script type="text/javascript">

    "use strict";

    function toggleAssets(button) {

        const card = button.closest(".transaction-card");

        if (!card) return;

        const details = card.querySelector(".asset-details");

        if (!details) return;

        const expanded =
            button.getAttribute("aria-expanded") === "true";

        details.style.display =
            expanded ? "none" : "block";

        button.textContent =
            expanded ? "+" : "\u2212";

        button.setAttribute(
            "aria-expanded",
            expanded ? "false" : "true"
        );

        button.setAttribute(
            "aria-label",
            expanded ? "Show asset details" : "Hide asset details"
        );

        card.classList.toggle("is-expanded", !expanded);
    }

</script>

</body>
</html>
