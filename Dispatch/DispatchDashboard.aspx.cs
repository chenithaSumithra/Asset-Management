
using Asset_Management.Connection;
using Asset_Management.DAL;
using Asset_Management.Helpers;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Drawing.Printing;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Asset_Management.Dispatch
{

    public partial class DispatchDashboard : Page
    {

      
       
        protected void Page_Load(object sender, EventArgs e)
        {
            int user = SessionHelper.GetUserId();
            Logger.Lo("Dispatch Dashboard SessionID: " + user);
           //FormAuthenticationDAL.checkFormPage(this, FormIDDistributor.DispatchDashboard, user);
            if (!IsPostBack)
            {
                LoadDispatchDashboard();
            }
        }


        protected void gvDispatch_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "CreateDispatch") return;

            string[] parts = Convert.ToString(e.CommandArgument).Split(new[] { '|' }, 2);

            string transferType = parts[0];
            string transactionTag = parts.Length > 1 ? parts[1] : string.Empty;

            if(string.IsNullOrWhiteSpace(transactionTag) || transactionTag == "-")
            {
                lblError.Text = "Invalid transaction";
                lblError.Visible = true;
                return;
            }

            Session["TransactionTag"] = transactionTag;
            Session["TransferType"] = transferType;


           

            Response.Redirect("~/Dispatch/DispatchNote.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private void LoadDispatchDashboard()
        {
            
            try
            {
                int user = SessionHelper.GetUserId();

                DataTable dt = new DataTable();

                using (SqlConnection conn = DBConnection.GetConnection())
                {
                    using (SqlCommand cmd = new SqlCommand(
                        "dbo.SP_DispatchDashboard", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        cmd.Parameters.Add("@Type", SqlDbType.Int).Value = 1;
                        cmd.Parameters.Add("@UserID", SqlDbType.Int).Value = user;
                        using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                        {
                            adapter.Fill(dt);
                        }
                    }
                }

                // Group transactions and their assets
                List<DispatchTransaction> transactions =
                    BuildDispatchTransactions(dt);

                // Bind grouped data to GridView
                gvDispatch.DataSource = transactions;
                gvDispatch.DataBind();
            }
            catch (Exception ex)
            {
                Logger.Lo("Dispatch Dashboard Error: " + ex.ToString());

                lblError.Text = "Unable to load dispatch transactions.";
                lblError.Visible = true;

                gvDispatch.Visible = false;
            }
        }

        private List<DispatchTransaction> BuildDispatchTransactions(
            DataTable dt)
        {
            List<DispatchTransaction> transactions =
                new List<DispatchTransaction>();

            Dictionary<Tuple<string, string>, DispatchTransaction> lookup =
                new Dictionary<Tuple<string, string>, DispatchTransaction>();

            foreach (DataRow row in dt.Rows)
            {
                string transferType = GetText(row, "TransferType");
                string transactionTag = GetText(row, "TransactionTag");

                // Combine source and tag to avoid grouping
                // Company and Supplier transactions together
                var key = Tuple.Create(transferType, transactionTag);

                DispatchTransaction transaction;

                if (!lookup.TryGetValue(key, out transaction))
                {
                    transaction = new DispatchTransaction();

                    transaction.TransferType = transferType;
                    transaction.TransactionTag = transactionTag;

                    transaction.IsDeclined = Convert.ToString(row["Status"]).Trim() == "3";
                    transaction.UserID =
                        GetText(row, "UserID");

                    transaction.CanView =
                        HasApproval(row["Status"]);

                    transaction.Destination =
                        GetText(row, "Destination");

                    transaction.ApproveNote =
                        GetText(row, "ApproveNote");

                    transaction.Comment =
                        GetText(row, "Comment");

                    transaction.StatusName =
                        GetText(row, "StatusName");

                    transaction.CreatedAT =
                        GetText(row, "CreatedAT");

                    // Format approved date
                    if (row["StatusUpdateDate"] != DBNull.Value)
                    {
                        transaction.ApprovedOn =
                            Convert.ToDateTime(row["StatusUpdateDate"])
                            .ToString("dd MMM yyyy, hh:mm tt");
                    }
                    else
                    {
                        transaction.ApprovedOn = "-";
                    }

                    transaction.Assets = new List<DispatchAsset>();

                    lookup.Add(key, transaction);
                    transactions.Add(transaction);
                }

                // Add the asset to its parent transaction
                DispatchAsset asset = new DispatchAsset();

                asset.AssetName = GetText(row, "AssetName");
                asset.Serial = GetText(row, "Serial");
                asset.MachineNo = GetText(row, "MachineNo");

                transaction.Assets.Add(asset);
            }

            return transactions;
        }

        protected string GetStatusClass(object statusName)
        {
            switch ((Convert.ToString(statusName) ?? "").Trim().ToLowerInvariant())
            {
                case "approved":
                    return "status-approved";

                case "declined":
                    return "status-declined";

                case "external approval pending":
                    return "status-pending";
                default:
                    return "";
            }
        }

        private static bool HasApproval(object value)
        {
            if(value == null || value == DBNull.Value)
            {
                return false;
            }

            string text = Convert.ToString(value).Trim();

            return text.Length > 0 && text != "0" && text == "2";
        }

        // Handle SQL NULL and empty values safely
        private static string GetText(DataRow row, string columnName)
        {
            if (row.IsNull(columnName))
            {
                return "-";
            }

            string value = Convert.ToString(row[columnName]);

            return string.IsNullOrWhiteSpace(value)
                ? "-"
                : value.Trim();
        }

        // Parent transaction model
        public class DispatchTransaction
        {
            public string TransferType { get; set; }
            public string TransactionTag { get; set; }
            public string UserID { get; set; }
            public string ApprovedOn { get; set; }
            public string Destination { get; set; }
            public string ApproveNote { get; set; }
            public string Comment { get; set; }
            public bool CanView { get; set; }
            public string StatusName { get; set; }
            public string CreatedAT { get; set; }
            public bool IsDeclined { get; set; }

            public List<DispatchAsset> Assets { get; set; }

            public int AssetCount
            {
                get
                {
                    return Assets == null ? 0 : Assets.Count;
                }
            }

            public string StatusDateLabel
            {
                get
                {
                    return IsDeclined ? "Declined On:" : "Approved On:";
                }
            }

            public string StatusNoteLabel
            {
                get
                {
                    return IsDeclined ? "Disapprove Note:" : "Approval Note:";
                }
            }
        }

        // Individual asset model
        public class DispatchAsset
        {
            public string AssetName { get; set; }
            public string Serial { get; set; }
            public string MachineNo { get; set; }
        }
    }
}
