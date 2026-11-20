using Asset_Management.Connection;
using Asset_Management.Helpers;
using System;
using System.Data;
using System.Data.SqlClient;

namespace Asset_Management.Dispatch
{
    public partial class DispatchNote : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadDispatchNote();
            }
        }

        private void LoadDispatchNote()
        {
            string tag = Session["TransactionTag"] as string;
            string type = Session["TransferType"] as string;

            if (string.IsNullOrEmpty(tag) || string.IsNullOrEmpty(type))
            {
                RedirectToDashboard();
                return;
            }

            try
            {
                DataTable dt = new DataTable();

                using (SqlConnection conn = DBConnection.GetConnection())
                using (SqlCommand cmd = new SqlCommand("dbo.SP_DispatchDashboard", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add("@Type", SqlDbType.Int).Value = 2;
                    cmd.Parameters.Add("@TransferType", SqlDbType.NVarChar, 20).Value = type;
                    cmd.Parameters.Add("@TransactionTag", SqlDbType.NVarChar, 100).Value = tag;

                    using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                    {
                        adapter.Fill(dt);
                    }
                }

                Logger.Lo("DispatchNote loaded " + dt.Rows.Count + " asset(s) for " + type + " / " + tag);

                if (dt.Rows.Count == 0)
                {
                    RedirectToDashboard();
                    return;
                }

                // Header values are the same on every row, so read them from the first row.
                DataRow first = dt.Rows[0];

                litDesNumber.Text = GetText(first, "TransactionTag");
                litDesDate.Text = GetDate(first, "StatusUpdateDate");
                litDesBy.Text = GetText(first, "ApprovedUserID");
                litDeliveryCompany.Text = GetText(first, "Destination");
                litDesComment.Text = GetText(first, "Comment");

                // One grid row per asset.
                rptDispatchItems.DataSource = dt;
                rptDispatchItems.DataBind();
            }
            catch (Exception ex)
            {
                Logger.Lo("DispatchNote Load Error: " + ex);
            }
        }

        private void RedirectToDashboard()
        {
            Response.Redirect("~/Dispatch/DispatchDashboard.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private static string GetText(DataRow row, string column)
        {
            if (!row.Table.Columns.Contains(column) || row.IsNull(column))
                return string.Empty;

            return Convert.ToString(row[column]);
        }

        private static string GetDate(DataRow row, string column)
        {
            if (!row.Table.Columns.Contains(column) || row.IsNull(column))
                return string.Empty;

            return Convert.ToDateTime(row[column]).ToString("dd/MM/yyyy");
        }
    }
}
