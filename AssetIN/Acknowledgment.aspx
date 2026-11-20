<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Acknowledgment.aspx.cs" Inherits="Asset_Management.AssetIN.Acknowledgment" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Acknowledgment
    </title>

    <meta name="viewport"
        content="width=device-width, initial-scale=1.0" />

    <link rel="stylesheet"
        href="<%= ResolveUrl("~/Vendor/fonts/inter/inter.css") %>" />

    <link rel="stylesheet" href="../Style/Header.css" />
    <link rel="stylesheet" href="../Style/style.css" />

    <script src="<%= ResolveUrl("~/Vendor/sweetalert2/sweetalert2.all.min.js") %>"></script>

</head>

<body>
    <form id="form1" runat="server">

        <div class="grid-container">
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
                        Manage Acknowledgment
                    </h2>

                    <p class="description"> Manage Acknowledgment</p>
                </div>
            </div>




        </div>
    </form>
</body>
</html>
