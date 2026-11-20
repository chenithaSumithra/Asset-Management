
<%@ Page Language="C#"
    AutoEventWireup="true"
    CodeBehind="ManageApprovals.aspx.cs"
    Inherits="Asset_Management.Approval.ManageApproval" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">

    <title>Manage Approvals</title>

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0" />

    <link rel="stylesheet"
          href="<%= ResolveUrl("~/Vendor/fonts/inter/inter.css") %>" />

    <link rel="stylesheet" href="../Style/Header.css"/>
    <link rel="stylesheet" href="../Style/style.css"/>

    <script src="<%= ResolveUrl("~/Vendor/sweetalert2/sweetalert2.all.min.js") %>"></script>
    
  

</head>

<body>

<form id="form1" runat="server">

    <div class="grid-container">

       <div class="transfer-page-header">
           <a href='<%= ResolveUrl("~/Home.aspx") %>'
               class="transfer-home-btn"
               title="Home"
               aria-label="Go to Home"
               >
                    <svg xmlns="http://www.w3.org/2000/svg"
                        width="23"
                        height="23"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round">

                    <path d="m3 10 9-7 9 7"/>
                    <path d="M5 9v12h14V9"/>
                    <path d="M9 21v-7h6v7"/>

                    </svg>
           </a>

           <div class="transfer-page-heading">
               <h2 class="page-title">
                   Manage Approval
               </h2>

               <p class="description">
                   Manage External Approvals
               </p>
           </div>

       </div>

        <div class="table-wrapper">

            <asp:GridView
                ID="gvApprovals"
                runat="server"
                AutoGenerateColumns="False"
                CssClass="approval-grid"
                GridLines="None"
                ShowHeader="False"
                EmptyDataText="No pending approvals found.">

                <Columns>

                    <asp:TemplateField>

                        <ItemTemplate>

                            <div class="transaction-card"
                                 data-transfer-source='<%#: Eval("TransferSource") %>'>

                                <!-- HEADER -->

                                <div class="transaction-header">

                                    <div class="transaction-title">

                                        <button
                                            type="button"
                                            class="btn btn-toggle"
                                            aria-expanded="false"
                                            onclick="toggleAssets(this)">
                                            +
                                        </button>

                                        <span class="transaction-tag">
                                            <%#: Eval("ExternalTransID") %>
                                        </span>

                                        <!-- COMPANY / SUPPLIER -->

                                        <span
                                            class='transfer-source <%# Convert.ToString(Eval("TransferSource")) == "Company" ? "transfer-company" : "transfer-supplier" %>'>

                                            <%#: Eval("TransferSource") %>

                                        </span>

                                        <span class="asset-count">
                                            <%#: Eval("AssetCount") %>
                                            Assets
                                        </span>

                                    </div>

                                    <!-- ACTION BUTTONS -->

                                    <div class="actions">

                                        <button
                                            type="button"
                                            class="btn btn-approve"
                                            onclick="confirmStatus(this, 1)">
                                            Approve
                                        </button>

                                        <button
                                            type="button"
                                            class="btn btn-reject"
                                            onclick="confirmStatus(this, 2)">
                                            Reject
                                        </button>

                                    </div>

                                </div>

                                <!-- TRANSACTION INFORMATION -->

                                <div class="transaction-meta">

                                    <span>
                                        Vendor:
                                        <strong>
                                            <%#: Eval("VendorName") %>
                                        </strong>
                                    </span>

                                    <span>
                                        Company:
                                        <strong>
                                            <%#: Eval("ToCompany") %>
                                        </strong>
                                    </span>

                                    <span>
                                        Created:
                                        <strong>
                                            <%#: Eval("CreatedAt") %>
                                        </strong>
                                    </span>

                                    <span>
                                        Expected Return:
                                        <strong>
                                            <%#: Eval("ExpectedCheckin") %>
                                        </strong>
                                    </span>

                                </div>

                                <!-- EXPANDABLE ASSET DETAILS -->

                                <div class="asset-details">

                                    <table class="child-table">

                                        <thead>
                                            <tr>
                                                <th>Asset ID</th>
                                                <th>Serial</th>
                                                <th>Manufacture</th>
                                                <th>Machine No</th>
                                                <th>Model</th>
                                                <th>Location</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>

                                        <tbody>

                                            <asp:Repeater
                                                ID="rptAssets"
                                                runat="server"
                                                DataSource='<%# Eval("Assets") %>'>

                                                <ItemTemplate>

                                                    <tr>

                                                        <td class="asset-id">
                                                            <%#: Eval("AssetID") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("Serial") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("Manufacture") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("MachineNo") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("Model") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("locationName") %>
                                                        </td>

                                                        <td>
                                                            <%#: Eval("StatusName") %>
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

<script type="text/javascript">

    "use strict";

    // ===============================================
    // EXPAND / COLLAPSE ASSETS
    // ===============================================

    function toggleAssets(button) {

        const card = button.closest(".transaction-card");

        if (!card) return;

        const details =
            card.querySelector(".asset-details");

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
    }

    // ===============================================
    // APPROVE / REJECT TRANSACTION
    // ===============================================

    async function confirmStatus(button, status) {

        const card = button.closest(".transaction-card");

        if (!card) return;

        const tagElement =
            card.querySelector(".transaction-tag");

        if (!tagElement) return;

        const transactionTag =
            tagElement.textContent.trim();

        // Identify Company or Supplier
        const transferSource =
            card.getAttribute("data-transfer-source");

        if (!transactionTag) {
            await Swal.fire({
                icon: "error",
                title: "Invalid Transaction",
                text: "Transaction tag is missing."
            });

            return;
        }

        if (transferSource !== "Company" &&
            transferSource !== "Supplier") {

            await Swal.fire({
                icon: "error",
                title: "Invalid Transfer",
                text: "Transfer source is invalid."
            });

            return;
        }

        const isApprove = status === 1;

        // ===========================================
        // CONFIRMATION POPUP
        // ===========================================

        const confirmation = await Swal.fire({

            title: isApprove
                ? "Approve Transaction"
                : "Reject Transaction",

            html:
                "<strong>Transaction:</strong> " +
                escapeHtml(transactionTag) +
                "<br/><strong>Transfer Type:</strong> " +
                escapeHtml(transferSource),

            icon: isApprove ? "question" : "warning",

            input: "textarea",

            inputLabel: isApprove
                ? "Approval Note"
                : "Rejection Reason",

            inputPlaceholder:
                "Enter your note...",

            inputAttributes: {
                maxlength: 2000
            },

            inputValidator: function (value) {

                if (!value || !value.trim()) {
                    return "Please enter a note.";
                }

                if (value.trim().length > 2000) {
                    return "Maximum 2000 characters allowed.";
                }

                return null;
            },

            showCancelButton: true,

            confirmButtonText: isApprove
                ? "Yes, Approve"
                : "Yes, Reject",

            confirmButtonColor: isApprove
                ? "#16a34a"
                : "#dc2626",

            allowOutsideClick: false

        });

        if (!confirmation.isConfirmed) {
            return;
        }

        const buttons =
            card.querySelectorAll("button");

        buttons.forEach(function (btn) {
            btn.disabled = true;
        });

        try {

            // =======================================
            // ASP.NET WEBMETHOD REQUEST
            // =======================================

            const response = await fetch(
                '<%= ResolveUrl("~/Approvals/ManageApprovals.aspx/UpdateApprovalStatus") %>',
                {
                    method: "POST",

                    headers: {
                        "Content-Type":
                            "application/json; charset=utf-8"
                    },

                    credentials: "same-origin",

                    body: JSON.stringify({

                        transactionTag: transactionTag,

                        transferSource: transferSource,

                        status: status,

                        note: confirmation.value.trim()

                    })
                }
            );

            if (!response.ok) {

                throw new Error(
                    "HTTP request failed: " +
                    response.status
                );
            }

            const data = await response.json();

            const result = data.d;

            if (!result || !result.Success) {

                throw new Error(
                    result && result.Message
                        ? result.Message
                        : "Transaction update failed."
                );
            }

            // =======================================
            // SUCCESS POPUP
            // =======================================

            await Swal.fire({

                icon: "success",

                title: isApprove
                    ? "Transaction Approved"
                    : "Transaction Rejected",

                text: result.Message,

                confirmButtonColor: "#2563eb"

            });

            // Reload approval records
            window.location.reload();

        }
        catch (error) {

            console.error(
                "Approval Error:",
                error
            );

            await Swal.fire({

                icon: "error",

                title: "Transaction Failed",

                text: error.message ||
                    "Unable to process transaction."

            });

        }
        finally {

            buttons.forEach(function (btn) {
                btn.disabled = false;
            });

        }
    }

    // ===============================================
    // HTML ENCODING FOR POPUP CONTENT
    // ===============================================

    function escapeHtml(value) {

        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

</script>

</body>
</html>
