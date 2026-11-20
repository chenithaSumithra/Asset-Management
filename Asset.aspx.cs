
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;
using ClosedXML.Excel;
using Asset_Management.Connection;

namespace Asset_Management
{
    public partial class Asset : System.Web.UI.Page
    {
        // EXISTING: Load data when page first opens
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadAssets();
            }
        }

        // NEW: Reusable method to retrieve assets
        private DataTable GetAssetsData(bool applySearch = true)
        {
            DataTable dt = new DataTable();

            string search = applySearch
                ? txtSearch.Text.Trim()
                : "";

            using (SqlConnection conn =
                DBConnection.GetConnection())

            using (SqlCommand cmd =
                new SqlCommand("dbo.getAllAssets", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.Add(
                    "@Type",
                    SqlDbType.Int
                ).Value = 1;

                cmd.Parameters.Add(
                    "@Search",
                    SqlDbType.NVarChar,
                    255
                ).Value = string.IsNullOrWhiteSpace(search)
                    ? (object)DBNull.Value
                    : search;

                using (SqlDataAdapter adapter =
                    new SqlDataAdapter(cmd))
                {
                    adapter.Fill(dt);
                }
            }

            return dt;
        }

        // UPDATED: Existing GridView loading method
        private void LoadAssets()
        {
            lblMessage.Text = "";

            try
            {
                DataTable dt = GetAssetsData();

                int totalPages = (int)Math.Ceiling(
                    (double)dt.Rows.Count / gvAssets.PageSize
                );

                if (totalPages == 0)
                {
                    gvAssets.PageIndex = 0;
                }
                else if (gvAssets.PageIndex >= totalPages)
                {
                    gvAssets.PageIndex = totalPages - 1;
                }

                gvAssets.DataSource = dt;
                gvAssets.DataBind();

                if (dt.Rows.Count == 0)
                {
                    lblMessage.Text = "No assets found.";
                }
                else
                {
                    lblMessage.Text =
                        dt.Rows.Count + " asset(s) found.";
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError(
                    "Asset loading error: " + ex.ToString()
                );

                gvAssets.DataSource = null;
                gvAssets.DataBind();

                lblMessage.Text =
                    "Unable to load assets. Please try again.";
            }
        }

        // EXISTING: Search button
        protected void btnSearch_Click(
            object sender,
            EventArgs e)
        {
            gvAssets.PageIndex = 0;
            LoadAssets();
        }

        // EXISTING: GridView paging event
        protected void gvAssets_PageIndexChanging(
            object sender,
            GridViewPageEventArgs e)
        {
            gvAssets.PageIndex = e.NewPageIndex;
            LoadAssets();
        }

        // NEW: Excel export button event
        protected void btnExportExcel_Click(
            object sender,
            EventArgs e)
        {
            try
            {
                // STEP 1: Read selected column indexes
                List<int> visibleColumns = new List<int>();

                string[] selected =
                    hfVisibleColumns.Value.Split(',');

                foreach (string item in selected)
                {
                    int index;

                    if (int.TryParse(item, out index))
                    {
                        if (index >= 0 &&
                            index < gvAssets.Columns.Count &&
                            !visibleColumns.Contains(index))
                        {
                            visibleColumns.Add(index);
                        }
                    }
                }

                if (visibleColumns.Count == 0)
                {
                    lblMessage.Text =
                        "Please select at least one column.";
                    return;
                }

                // Preserve GridView column order
                visibleColumns.Sort();

                // STEP 2: Load ALL records from database
                // false = ignore search and fetch all assets
                DataTable dt = GetAssetsData(false);

                // STEP 3: Create workbook
                using (XLWorkbook workbook = new XLWorkbook())
                {
                    var worksheet =
                        workbook.Worksheets.Add("Assets");

                    // STEP 4: Write selected column headers
                    for (int col = 0;
                         col < visibleColumns.Count;
                         col++)
                    {
                        int gridIndex = visibleColumns[col];

                        worksheet.Cell(1, col + 1).Value =
                            gvAssets.Columns[gridIndex].HeaderText;
                    }

                    // STEP 5: Write ALL asset records
                    for (int row = 0; row < dt.Rows.Count; row++)
                    {
                        for (int col = 0;
                             col < visibleColumns.Count;
                             col++)
                        {
                            int gridIndex = visibleColumns[col];

                            var cell =
                                worksheet.Cell(row + 2, col + 1);

                            // First GridView column is a
                            // generated row number (ID)
                            if (gridIndex == 0)
                            {
                                cell.Value = row + 1;
                                continue;
                            }

                            // Get DataField from GridView
                            BoundField field =
                                gvAssets.Columns[gridIndex]
                                as BoundField;

                            if (field == null)
                            {
                                continue;
                            }

                            string dataField = field.DataField;

                            if (!dt.Columns.Contains(dataField))
                            {
                                throw new InvalidOperationException(
                                    "Missing database column: " + dataField
                                );
                            }

                            object value =
                                dt.Rows[row][dataField];

                            if (value == DBNull.Value)
                            {
                                cell.Value = "";
                            }
                            else if (value is DateTime)
                            {
                                cell.Value = (DateTime)value;

                                cell.Style.DateFormat.Format =
                                    "yyyy-mm-dd";
                            }
                            else if (
                                dataField.Equals(
                                    "Cost",
                                    StringComparison.OrdinalIgnoreCase
                                ) && value is decimal)
                            {
                                cell.Value =
                                    Convert.ToDouble((decimal)value);

                                cell.Style.NumberFormat.Format =
                                    "#,##0.00";
                            }
                            else
                            {
                                // Preserve identifiers and
                                // serial numbers as text
                                cell.Value = Convert.ToString(value);
                            }
                        }
                    }

                    // STEP 6: Format the Excel header
                    var headerRange = worksheet.Range(
                        1, 1, 1, visibleColumns.Count
                    );

                    headerRange.Style.Font.Bold = true;

                    headerRange.Style.Fill.BackgroundColor =
                        XLColor.FromHtml("#EAF2FF");

                    // STEP 7: Freeze header and fit columns
                    worksheet.SheetView.FreezeRows(1);

                    worksheet.Columns().AdjustToContents();

                    if (dt.Rows.Count > 0)
                    {
                        worksheet.RangeUsed().SetAutoFilter();
                    }

                    // STEP 8: Send Excel file to browser
                    using (MemoryStream stream = new MemoryStream())
                    {
                        workbook.SaveAs(stream);

                        byte[] fileBytes = stream.ToArray();

                        string fileName =
                            "Assets_" +
                            DateTime.Now.ToString("yyyyMMdd_HHmmss") +
                            ".xlsx";

                        Response.Clear();
                        Response.Buffer = true;

                        Response.ContentType =
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

                        Response.AddHeader(
                            "Content-Disposition",
                            "attachment; filename=" + fileName
                        );

                        Response.BinaryWrite(fileBytes);

                        Response.Flush();

                        Context.ApplicationInstance
                            .CompleteRequest();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError(
                    "Excel export error: " + ex.ToString()
                );

                lblMessage.Text =
                    "Unable to export assets. Please try again.";
            }
        }
    }
}
