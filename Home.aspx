<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="Home.aspx.cs"
    Inherits="Asset_Management.Home" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Home | Asset Management</title>

    <meta name="viewport"
        content="width=device-width, initial-scale=1.0" />

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #f3f7fd;
            color: #1e293b;
            min-height: 100vh;
        }

        /* HEADER */

        .home-header {
            background: linear-gradient( 120deg, #0f3c87, #1565c0, #2584e9 );
            padding: 45px 25px 85px;
            color: white;
            text-align: center;
        }

            .home-header h1 {
                font-size: 32px;
                font-weight: 700;
                letter-spacing: -.5px;
                margin-bottom: 12px;
            }

            .home-header p {
                font-size: 15px;
                color: #dbeafe;
                line-height: 1.6;
            }

        /* MAIN CONTENT */

        .home-container {
            max-width: 1150px;
            margin: -45px auto 0;
            padding: 0 24px 60px;
            position: relative;
        }

        .home-panel {
            background: white;
            border-radius: 18px;
            padding: 35px;
            box-shadow: 0 12px 40px rgba(24, 70, 130, .08);
            border: 1px solid #e6edf7;
        }

        .section-title {
            font-size: 20px;
            font-weight: 700;
            color: #183b67;
            margin-bottom: 8px;
        }

        .section-description {
            font-size: 14px;
            color: #64748b;
            margin-bottom: 30px;
        }

        /* CARD GRID */

        .menu-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 22px;
        }

        .menu-card {
            display: flex;
            flex-direction: column;
            text-decoration: none;
            background: #ffffff;
            border: 1px solid #dce8f8;
            border-radius: 15px;
            padding: 28px 24px;
            min-height: 230px;
            position: relative;
            transition: all .25s ease;
        }

            .menu-card:hover {
                transform: translateY(-6px);
                border-color: #3b82f6;
                background: #f8fbff;
                box-shadow: 0 14px 30px rgba(37, 99, 235, .12);
            }

            .menu-card:focus-visible {
                outline: 3px solid #60a5fa;
                outline-offset: 4px;
            }

        /* ICON */

        .menu-icon {
            width: 60px;
            height: 60px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 15px;
            background: #eaf3ff;
            color: #1565c0;
            margin-bottom: 23px;
            transition: .25s;
        }

            .menu-icon svg {
                width: 30px;
                height: 30px;
                stroke: currentColor;
                fill: none;
                stroke-width: 1.8;
                stroke-linecap: round;
                stroke-linejoin: round;
            }

        .menu-card:hover .menu-icon {
            background: #1565c0;
            color: white;
        }

        /* CARD CONTENT */

        .menu-title {
            font-size: 18px;
            font-weight: 700;
            color: #1e3a5f;
            margin-bottom: 10px;
        }

        .menu-description {
            font-size: 13px;
            color: #64748b;
            line-height: 1.7;
            margin-bottom: 20px;
        }

        .menu-link {
            margin-top: auto;
            display: flex;
            align-items: center;
            gap: 8px;
            color: #1565c0;
            font-size: 13px;
            font-weight: 700;
        }

        .menu-arrow {
            font-size: 19px;
            transition: transform .25s;
        }

        .menu-card:hover .menu-arrow {
            transform: translateX(5px);
        }

        /* FOOTER */

        .home-footer {
            text-align: center;
            color: #94a3b8;
            font-size: 12px;
            padding: 20px;
        }

        /* RESPONSIVE */

        @media (max-width: 900px) {
            .menu-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 600px) {
            .home-header {
                padding: 35px 20px 75px;
            }

                .home-header h1 {
                    font-size: 25px;
                }

            .home-container {
                padding: 0 15px 35px;
            }

            .home-panel {
                padding: 25px 18px;
            }

            .menu-grid {
                grid-template-columns: 1fr;
                gap: 15px;
            }

            .menu-card {
                min-height: 200px;
                padding: 22px;
            }
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <!-- HEADER -->
        <header class="home-header">
            <h1>Asset Management System</h1>
            <p>
                Manage assets, transfers and approvals
                from one centralized workspace.
            </p>
        </header>

        <!-- MAIN -->
        <main class="home-container">

            <section class="home-panel">

                <h2 class="section-title">Quick Access
                </h2>

                <p class="section-description">
                    Select a module to continue.
                </p>

                <div class="menu-grid">

                    <!-- ASSET MASTER -->
                    <a class="menu-card"
                        href='<%= ResolveUrl("~/Asset.aspx") %>'
                    >

                        <div class="menu-icon">
                            <svg viewBox="0 0 24 24">
                                <rect x="3" y="3"
                                    width="7" height="7"
                                    rx="1" />
                                <rect x="14" y="3"
                                    width="7" height="7"
                                    rx="1" />
                                <rect x="3" y="14"
                                    width="7" height="7"
                                    rx="1" />
                                <rect x="14" y="14"
                                    width="7" height="7"
                                    rx="1" />
                            </svg>
                        </div>

                        <h3 class="menu-title">Asset Master
                        </h3>

                        <p class="menu-description">
                            View and manage asset records,
                            inventory information and details.
                        </p>

                        <span class="menu-link">Open Asset Master
                            <span class="menu-arrow">&rarr;
                            </span>
                        </span>

                    </a>

                    <!-- CHECKOUT ASSET -->
                    <a class="menu-card"
                        href='<%= ResolveUrl("~/Transfer/ManageTransfer.aspx") %>'
                      >

                        <div class="menu-icon">
                            <svg viewBox="0 0 24 24">
                                <path d="M4 7h15" />
                                <path d="M15 3l4 4-4 4" />
                                <path d="M20 17H5" />
                                <path d="M9 13l-4 4 4 4" />
                            </svg>
                        </div>

                        <h3 class="menu-title">Transaction Asset
                        </h3>

                        <p class="menu-description">
                            Process internal and external
                            asset transfers and checkouts.
                        </p>

                        <span class="menu-link">Manage Transfers
                            <span class="menu-arrow">&rarr;
                            </span>
                        </span>

                    </a>

                    <!-- APPROVALS -->
                    <a class="menu-card"
                        href='<%= ResolveUrl("~/Approvals/ManageApprovals.aspx") %>'
                      >

                        <div class="menu-icon">
                            <svg viewBox="0 0 24 24">
                                <rect x="5" y="4"
                                    width="14" height="17"
                                    rx="2" />
                                <path d="M9 4.5V3h6v1.5" />
                                <path d="M8.5 13l2.5 2.5L16 10" />
                            </svg>
                        </div>

                        <h3 class="menu-title">Approvals
                        </h3>

                        <p class="menu-description">
                            Review pending asset transfers
                            and manage approval requests.
                        </p>

                        <span class="menu-link">Manage Approvals
                            <span class="menu-arrow">&rarr;
                            </span>
                        </span>

                    </a>


              

                    <!-- Dispatch Dashboard -->
                    <a class="menu-card"
                        href='<%= ResolveUrl("~/Dispatch/DispatchDashboard.aspx") %>'
                     >

                        <div class="menu-icon">
                            <svg viewBox="0 0 24 24">
                                <rect x="5" y="4"
                                    width="14" height="17"
                                    rx="2" />
                                <path d="M9 4.5V3h6v1.5" />
                                <path d="M8.5 13l2.5 2.5L16 10" />
                            </svg>
                        </div>

                        <h3 class="menu-title">Dispatch Dashboard
                        </h3>

                        <p class="menu-description">
                            Review All Successful External 
         Transfers and Create Dispatch Note
                        </p>

                        <span class="menu-link"> Dispatch Dashboard
         <span class="menu-arrow">&rarr;
         </span>
                        </span>
                    </a>

                </div>

            </section>

        </main>

        <!-- FOOTER -->
        <footer class="home-footer">
            Asset Management System
        </footer>

    </form>
</body>
</html>