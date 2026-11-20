<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DispatchNote.aspx.cs" Inherits="Asset_Management.Dispatch.DispatchNote" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">

    <title>Dispatch Note | Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <link rel="stylesheet" href="../Style/AssetBarCode.css" />
    <link rel="stylesheet" href="../Style/ManageTransfer-additions.css?v=8" />
    <link rel="stylesheet" href="../Style/Header.css" />
    <link rel="stylesheet" href="../Style/DispatchNote.css" />

</head>

<body>

    <form id="form1" runat="server">

        <main class="report-workspace">

            <div class="report-toolbar">

                <div class="toolbar-heading">

               
                    <a href='<%= ResolveUrl("~/Home.aspx") %>'
                        class="transfer-home-btn"
                        title="Home"
                        aira-label="Go to Home">
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

                </div>


                <button type="button"
                    class="print-button"
                    onclick="window.print()">

                    <svg viewBox="0 0 24 24"
                        aria-hidden="true">

                        <path d="M6 9V3h12v6" />

                        <path d="M6 18H4a2 2 0 0 1-2-2v-5a3 3 0 0 1 3-3h14a3 3 0 0 1 3 3v5a2 2 0 0 1-2 2h-2" />

                        <path d="M6 14h12v7H6z" />

                        <path d="M18 11h.01" />

                    </svg>

                    Print Report

                </button>

            </div>

            <article class="dispatch-container">

                <!-- WATERMARK -->

                <div class="watermark">
                    Duplicate<br />
                    Copy
                </div>


                <div class="report-content">

                
                    <header class="dispatch-header">

                        <p class="company-name">
                            Sumithra Garments (Pte) Ltd.
                        </p>

                        <p class="company-address">
                            No. 33, Thelangapatha Road, Wattala.
                        </p>

                        <h2 class="dispatch-title">Dispatch Note
                        </h2>

                    </header>



                    <section class="dispatch-details">

                        <!-- LEFT DETAILS -->

                        <div class="details-left">

                            <div class="details-row">
                                <span class="details-label">DES. NUMBER:
                                </span>
                                <span class="details-value">
                                    <asp:Literal ID="litDesNumber" runat="server" Mode="Encode" />
                                </span>
                            </div>

                            <div class="details-row">
                                <span class="details-label">DES. DATE:
                                </span>
                                <span class="details-value">
                                    <asp:Literal ID="litDesDate" runat="server" Mode="Encode"/>
                                </span>
                            </div>

                            <div class="details-row">
                                <span class="details-label">ATTENTION:
                                </span>
                                <span class="details-value">
                                </span>
                            </div>

                            <div class="details-row">
                                <span class="details-label">YOUR ORDER NO:
                                </span>
                                <span class="details-value">&nbsp;
                                </span>
                            </div>

                            <div class="details-row">
                                <span class="details-label">VEHICLE NO:
                                </span>
                                <span class="details-value">&nbsp;
                                </span>
                            </div>

                            <div class="details-row">
                                <span class="details-label">OUR BILL NO:
                                </span>
                                <span class="details-value">&nbsp;
                                </span>
                            </div>

                            <div class="details-row">
                                <span class="details-label">DES COMMENT:
                                </span>
                                <span class="details-value">
                                    <asp:Literal ID="litDesComment" runat="server" Mode="Encode"/>
                                </span>
                            </div>

                        </div>


                        <!-- RIGHT DETAILS -->

                        <div class="details-right">

                            <div class="details-row">

                                <span class="details-label">DES BY:
                                </span>

                                <span class="details-value">
                                    <asp:Literal ID="litDesBy" runat="server" Mode="Encode" />
                                </span>

                            </div>

                            <div class="details-row">

                                <span class="details-label">DELIVERY COMPANY:
                                </span>

                                <span class="details-value">
                                    <asp:Literal ID="litDeliveryCompany" runat="server" Mode="Encode"/>
                                </span>

                            </div>

                        </div>

                    </section>



                    <div class="dispatch-table-wrapper">

                        <table class="dispatch-table">

                            <thead>

                                <tr>

                                    <th scope="col" class="col-no">No
                                    </th>

                                    <th scope="col" class="col-item">Item Name
                                    </th>

                                    <th scope="col" class="col-uom">Machine No.
                                    </th>

                               
                                    <th scope="col" class="col-uom">Serial No.
                                    </th>

                                </tr>

                            </thead>


                            <tbody>

                               <asp:Repeater ID="rptDispatchItems" runat="server">

                                   <ItemTemplate>

                                       <tr>
                                           <td class="col-no"><%# Container.ItemIndex + 1 %></td>

                                           <td class="col-item">
                                               <%# Server.HtmlEncode(Convert.ToString(Eval("AssetName"))) %>
                                             
                                           </td>

                                           <td class="col-item">
                                               <%# Server.HtmlEncode(Convert.ToString(Eval("MachineNo"))) %>
                                           </td>

                                           <td class="col-item">
                                               <%# Server.HtmlEncode(Convert.ToString(Eval("Serial"))) %>
                                           </td>
                                       </tr>
                                   </ItemTemplate>

                               </asp:Repeater>

                            </tbody>

                        </table>

                    </div>


                    <!-- ==================================
                     SIGNATURE SECTION
                =================================== -->

                    <section class="dispatch-signatures">

                        <div class="signature-block">

                            <span class="signature-label">Authorized By:
                            </span>

                            <span class="signature-line"></span>

                        </div>


                        <div class="signature-block">

                            <span class="signature-label">Transported By:
                            </span>

                            <span class="signature-line"></span>

                        </div>

                    </section>


                    <!-- ==================================
                     END OF REPORT
                =================================== -->

                    <footer class="end-report">
                        *** End Of Report ***
                    </footer>

                </div>

            </article>

        </main>

    </form>

</body>
</html>
