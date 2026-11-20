
using Asset_Management.Connection;
using Asset_Management.DAL;
using Asset_Management.Helpers;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;

namespace Asset_Management.Approval
{
    public partial class ManageApproval : Page
    {
      

        protected void Page_Load(object sender, EventArgs e)
        {
            int user = SessionHelper.GetUserId();
            FormAuthenticationDAL.checkFormPage(this, FormIDDistributor.ManageApprovals, user);


            if (!IsPostBack)
            {
                LoadApprovals();
            }
        }

        

        private void LoadApprovals()
        {
            try
            {
                DataTable dt = new DataTable();

                using (SqlConnection conn =
                    DBConnection.GetConnection())
                {
                    using (SqlCommand cmd =
                        new SqlCommand(
                            "dbo.SP_ManageApprovals",
                            conn))
                    {
                        cmd.CommandType =
                            CommandType.StoredProcedure;

                        cmd.Parameters.Add(
                            "@Type",
                            SqlDbType.Int
                        ).Value = 1;

                        using (SqlDataAdapter adapter =
                            new SqlDataAdapter(cmd))
                        {
                            adapter.Fill(dt);
                        }
                    }
                }

                // =======================================
                // GROUPED TRANSACTION TABLE
                // =======================================

                DataTable grouped = new DataTable();

                grouped.Columns.Add(
                    "ExternalTransID",
                    typeof(string));

                grouped.Columns.Add(
                    "TransferSource",
                    typeof(string));

                grouped.Columns.Add(
                    "VendorName",
                    typeof(string));

                grouped.Columns.Add(
                    "ToCompany",
                    typeof(string));

                grouped.Columns.Add(
                    "CreatedAt",
                    typeof(string));

                grouped.Columns.Add(
                    "ExpectedCheckin",
                    typeof(string));

                grouped.Columns.Add(
                    "AssetCount",
                    typeof(int));

                grouped.Columns.Add(
                    "Assets",
                    typeof(DataTable));

                // =======================================
                // GROUP COMPANY AND SUPPLIER SEPARATELY
                // =======================================

                // Group using both source and tag.
                // This prevents transactions with matching
                // tags in different tables from merging.

                var transactions = dt.AsEnumerable()
                    .GroupBy(row => new
                    {
                        TransferSource =
                            Convert.ToString(
                                row["TransferSource"]),

                        TransactionTag =
                            Convert.ToString(
                                row["ExternalTransID"])
                    });

                // =======================================
                // CREATE GROUPED ROWS
                // =======================================

                foreach (var transaction in transactions)
                {
                    DataRow first =
                        transaction.First();

                    DataTable assets =
                        dt.Clone();

                    foreach (DataRow asset in transaction)
                    {
                        assets.ImportRow(asset);
                    }

                    string createdAt =
                        FormatDate(
                            first["CreatedAt"]);

                    string expectedCheckin =
                        FormatDate(
                            first["ExpectedCheckin"]);

                    string vendorName =
                        Convert.ToString(
                            first["VendorName"]);

                    string toCompany =
                        Convert.ToString(
                            first["ToCompany"]);

                    grouped.Rows.Add(

                        transaction.Key.TransactionTag,

                        transaction.Key.TransferSource,

                        vendorName,

                        toCompany,

                        createdAt,

                        expectedCheckin,

                        assets.Rows.Count,

                        assets
                    );
                }

                // =======================================
                // BIND SINGLE GRIDVIEW
                // =======================================

                gvApprovals.DataSource = grouped;

                gvApprovals.DataBind();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "Load Approvals Error: " + ex);

                throw;
            }
        }

        // ===============================================
        // FORMAT DATE
        // ===============================================

        private static string FormatDate(
            object value)
        {
            if (value == null ||
                value == DBNull.Value)
            {
                return "-";
            }

            return Convert.ToDateTime(value)
                .ToString("yyyy-MM-dd");
        }

        // ===============================================
        // APPROVE / REJECT WEBMETHOD
        // ===============================================

        [WebMethod(EnableSession = true)]
        public static object UpdateApprovalStatus(
            string transactionTag,
            string transferSource,
            int status,
            string note)
        {
            try
            {
                // =======================================
                // VALIDATE APPROVAL STATUS
                // =======================================

                if (status != 1 && status != 2)
                {
                    return new
                    {
                        Success = false,
                        Message =
                            "Invalid approval type."
                    };
                }

                // =======================================
                // VALIDATE TRANSFER SOURCE
                // =======================================

                if (transferSource != "Company" &&
                    transferSource != "Supplier")
                {
                    return new
                    {
                        Success = false,
                        Message =
                            "Invalid transfer source."
                    };
                }

                // =======================================
                // VALIDATE TRANSACTION TAG
                // =======================================

                if (string.IsNullOrWhiteSpace(
                    transactionTag))
                {
                    return new
                    {
                        Success = false,
                        Message =
                            "Transaction tag is required."
                    };
                }

                transactionTag =
                    transactionTag.Trim();

                // =======================================
                // VALIDATE APPROVAL NOTE
                // =======================================

                if (string.IsNullOrWhiteSpace(note))
                {
                    return new
                    {
                        Success = false,
                        Message =
                            "Approval or rejection note is required."
                    };
                }

                note = note.Trim();

                if (note.Length > 2000)
                {
                    return new
                    {
                        Success = false,
                        Message =
                            "Note cannot exceed 2000 characters."
                    };
                }

                // =======================================
                // GET LOGGED-IN USER ID
                // =======================================

                HttpContext context =
                    HttpContext.Current;

                if (context == null ||
                    context.Session == null)
                {
                    return new
                    {
                        Success = false,
                        Message =
                            "Session is unavailable."
                    };
                }

                // Change this key if your
                // login system uses another key.

               

                int approvalUserId = 0;

                //if (sessionUser == null ||
                //    !int.TryParse(
                //        sessionUser.ToString(),
                //        out approvalUserId) ||
                //    approvalUserId <= 0)
                //{
                //    return new
                //    {
                //        Success = false,
                //        Message =
                //            "Session expired or user is invalid."
                //    };
                //}

              

                // =======================================
                // EXECUTE STORED PROCEDURE
                // =======================================

                using (SqlConnection conn =
                    DBConnection.GetConnection())
                {
                    using (SqlCommand cmd =
                        new SqlCommand(
                            "dbo.SP_UpdateApprovalStatus",
                            conn))
                    {
                        cmd.CommandType =
                            CommandType.StoredProcedure;

                        // 1 = Approve
                        // 2 = Reject

                        cmd.Parameters.Add(
                            "@Type",
                            SqlDbType.Int
                        ).Value = status;

                        // Logged-in approver

                        cmd.Parameters.Add(
                            "@ApprovalUserID",
                            SqlDbType.Int
                        ).Value = approvalUserId;

                        // Approval / Rejection note

                        cmd.Parameters.Add(
                            "@Note",
                            SqlDbType.NVarChar,
                            2000
                        ).Value = note;

                        // Transaction Tag

                        cmd.Parameters.Add(
                            "@TransactionID",
                            SqlDbType.NVarChar,
                            600
                        ).Value = transactionTag;

                        // Company or Supplier

                        cmd.Parameters.Add(
                            "@TransferSource",
                            SqlDbType.NVarChar,
                            20
                        ).Value = transferSource;

                        if (conn.State !=
                            ConnectionState.Open)
                        {
                            conn.Open();
                        }

                        cmd.ExecuteNonQuery();
                    }
                }

                // =======================================
                // SUCCESS RESPONSE
                // =======================================

                return new
                {
                    Success = true,

                    Message = status == 1
                        ? "Transaction approved successfully."
                        : "Transaction rejected successfully.",

                    TransactionTag = transactionTag,

                    TransferSource = transferSource
                };
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "SQL Approval Error: " + ex);

                return new
                {
                    Success = false,

                    Message =
                        "Database error while updating " +
                        "the transaction. Check server logs."
                };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "Update Approval Error: " + ex);

                return new
                {
                    Success = false,

                    Message =
                        "Unable to update transaction. " +
                        "Check server logs."
                };
            }
        }
    }
}
