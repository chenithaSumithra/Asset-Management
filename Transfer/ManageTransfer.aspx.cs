using Asset_Management.Connection;
using Asset_Management.DAL;
using Asset_Management.DAO;
using Asset_Management.Helpers;
using Asset_Management.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Services;
using System.Web.UI;

namespace Asset_Management.Transfer
{
    public partial class ManageTransfer : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            int user = SessionHelper.GetUserId();
            FormAuthenticationDAL.checkFormPage(this, FormIDDistributor.ManageTransfer, user);

            if (!IsPostBack)
            {
                LoadTotalAssetsCount();
                LoadCompanies();
                LoadLocations();
                LoadVendors();
                LoadCondition();
            }
        }

        private void LoadTotalAssetsCount()
        {
            try
            {
                using (SqlConnection conn = DBConnection.GetConnection())
                using (SqlCommand cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM dbo.assets_master", conn))
                {
                    int count = Convert.ToInt32(cmd.ExecuteScalar());

                    litTotalAssets.Text = count.ToString("N0");
                }
            }

            catch (Exception ex)
            {
                Logger("LoadAssets Error: " + ex.ToString());

                litTotalAssets.Text = "0";
            }
        }

        private static void Logger(string message)
        {
            System.Diagnostics.Debug.WriteLine(message);
        }

        private static string ReadValue(
            SqlDataReader reader,
            string columnName)
        {
            int index = reader.GetOrdinal(columnName);

            return reader.IsDBNull(index)
                ? ""
                : Convert.ToString(reader.GetValue(index));
        }

        // A stored procedure may omit optional display columns.
        // Return an empty value rather than failing the whole search.
        private static string ReadOptionalValue(SqlDataReader reader, string columnName)
        {
            for (int i = 0; i < reader.FieldCount; i++)
            {
                if (string.Equals(reader.GetName(i), columnName,
                    StringComparison.OrdinalIgnoreCase))
                {
                    return reader.IsDBNull(i) ? "" :
                        Convert.ToString(reader.GetValue(i));
                }
            }
            return "";
        }

        // GET ASSET USING BARCODE
        // (unchanged - the Success / Message it returns is shown
        //  in SweetAlert by ManageTransfer.js)
        [WebMethod]
        public static AssetLookupResponse GetAssetByBarcode(
            int barcodeId)
        {
            AssetLookupResponse result =
                new AssetLookupResponse();

            SqlConnection conn = null;

            try
            {
                if (barcodeId <= 0)
                {
                    //result.Success = false;
                    //result.Message = "Invalid barcode ID.";
                    return result;
                }

                conn = DBConnection.GetConnection();

                using (SqlCommand cmd = new SqlCommand(
                    "dbo.SP_GetAssetByBarCode", conn))
                {
                    cmd.CommandType =
                        CommandType.StoredProcedure;

                    cmd.Parameters.Add(
                        "@barcodeId",
                        SqlDbType.Int
                    ).Value = barcodeId;

                    using (SqlDataReader reader =
                        cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            AssetDetails asset =
                                new AssetDetails();

                            asset.BarcodeId =
                                barcodeId.ToString();

                            asset.AssetName =
                                ReadValue(reader, "AssetName");

                            asset.Serial =
                                ReadValue(reader, "Serial");

                            asset.MachineNo =
                                ReadValue(reader, "MachineNo");

                            asset.Model =
                                ReadValue(reader, "Model");

                            asset.Model_No =
                                ReadValue(reader, "Model_No");

                            asset.Status =
                                ReadValue(reader, "Status");

                            asset.StatusName =
                                ReadValue(reader, "StatusName");

                            asset.Condition = ReadValue(reader, "Condition");

                            asset.Company =
                                ReadValue(reader, "Company");

                            asset.CurrentLocation =
                                ReadValue(reader, "CurrentLocation");

                            result.Success = true;
                            result.Asset = asset;
                            
                        }
                        else
                        {
                            /*result.Success = false;
                            result.Message =
                                "No available asset found for barcode: "
                                + barcodeId;*/
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger("GetAssetByBarcode Error: " + ex);

                /*result.Success = false;
                result.Message =
                    "Unable to retrieve asset details.";*/
            }
            finally
            {
                DBConnection.CloseConnection(conn);
            }

            return result;
        }

        private void ShowClientMessage(string message, bool isError)
        {
            string script =
                "window.addEventListener('load',function(){notify(" +
                new JavaScriptSerializer().Serialize(message) + "," +
                (isError ? "true" : "false") + ");});";

            ClientScript.RegisterStartupScript(GetType(), "CondMsg", script, true);
        }

        // EXISTING SEARCH (unchanged)
        [WebMethod]
        public static object SearchAssets(string search)
        {
            List<object> assets = new List<object>();
            SqlConnection conn = null;

            try
            {
                if (string.IsNullOrWhiteSpace(search))
                {
                    return new
                    {
                        Success = true,
                        Assets = assets
                    };
                }

                search = search.Trim();

                if (search.Length > 255)
                {
                    return new
                    {
                        Success = false,
                        Message = "Search must not exceed 255 characters.",
                        Assets = assets
                    };
                }

                conn = DBConnection.GetConnection();

                // getAllAssets returns Status but not necessarily StatusName.
                // Load real labels from StatusMaster so search and QR scans
                // display the same status names and colors.
                Dictionary<int, string> statusNames =
                    new Dictionary<int, string>();
                try
                {
                    using (SqlCommand statusCmd = new SqlCommand(
                        "SELECT [id], [StatusName] FROM dbo.StatusMaster", conn))
                    using (SqlDataReader statusReader = statusCmd.ExecuteReader())
                    {
                        while (statusReader.Read())
                        {
                            int key = Convert.ToInt32(statusReader["id"]);
                            string name = statusReader.IsDBNull(1)
                                ? "" : Convert.ToString(statusReader["StatusName"]);
                            statusNames[key] = name;
                        }
                    }
                }
                catch (SqlException ex)
                {
                    // Still return search results when labels are unavailable.
                    Logger("StatusMaster lookup: " + ex.Message);
                }

                using (SqlCommand cmd = new SqlCommand(
                    "dbo.getAllAssets", conn))
                {
                    cmd.CommandType =
                        CommandType.StoredProcedure;

                    cmd.CommandTimeout = 30;

                    cmd.Parameters.Add(
                        "@Type", SqlDbType.Int
                    ).Value = 2;

                    cmd.Parameters.Add(
                        "@Search",
                        SqlDbType.NVarChar,
                        255
                    ).Value = search;

                    using (SqlDataReader reader =
                        cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string status = ReadValue(reader, "Status");
                            string statusName = ReadOptionalValue(reader, "StatusName");
                            int statusId;
                            if (string.IsNullOrWhiteSpace(statusName) &&
                                int.TryParse(status, out statusId))
                            {
                                string knownName;
                                if (statusNames.TryGetValue(statusId, out knownName))
                                    statusName = knownName;
                            }

                            assets.Add(new
                            {
                                BarcodeId =
                                    ReadValue(reader, "barcodeId"),

                                AssetName =
                                    ReadValue(reader, "AssetName"),

                                Serial =
                                    ReadValue(reader, "Serial"),

                                MachineNo =
                                    ReadValue(reader, "MachineNo"),

                                Model =
                                    ReadValue(reader, "Model"),

                                Model_No =
                                    ReadValue(reader, "Model_No"),

                                Company =
                                    ReadValue(reader, "Company"),

                                Manufacturer =
                                    ReadValue(reader, "Manufacturer"),

                                SubCategory =
                                    ReadValue(reader, "SubCategory"),

                                CurrentLocation =
                                    ReadValue(reader, "Location"),

                              

                                Status = status,

                                StatusName = statusName,

                                Condition =
                                    ReadOptionalValue(reader, "Condition")

                            });

                            if (assets.Count >= 30)
                                break;
                        }
                    }
                }

                return new
                {
                    Success = true,
                    Assets = assets
                };
            }
            catch (Exception ex)
            {
                Logger("SearchAssets Error: " + ex);

                return new
                {
                    Success = false,
                    Message = "Unable to search assets.",
                    Assets = assets
                };
            }
            finally
            {
                DBConnection.CloseConnection(conn);
            }
        }

        // SAVE INTERNAL OR EXTERNAL TRANSFER
        // (unchanged, same SP - the Success / Message it returns is
        //  shown in SweetAlert by ManageTransfer.js)
        [WebMethod(EnableSession = true)]
        public static object SaveCheckout(
            CheckoutRequest checkout)
        {
            SqlConnection conn = null;
            SqlTransaction trans = null;

            try
            {
                if (checkout == null ||
                    checkout.barcodeIds == null ||
                    checkout.barcodeIds.Count == 0)
                {
                    return new
                    {
                        Success = false,
                        Message = "No assets selected."
                    };
                }

                string checkoutType =
                    (checkout.checkoutType ?? "").Trim();

                bool isInternal = string.Equals(
                    checkoutType,
                    "Internal",
                    StringComparison.OrdinalIgnoreCase);

                bool isExternal = string.Equals(
                    checkoutType,
                    "External",
                    StringComparison.OrdinalIgnoreCase);

                if (!isInternal && !isExternal)
                {
                    return new
                    {
                        Success = false,
                        Message = "Invalid transfer type."
                    };
                }

                string destinationType =
                    (checkout.destinationType ?? "").Trim();

                int destinationId = 0;
                int? vendorId = null;
                string companyCode = null;
                DateTime? expectedCheckin = null;

                // INTERNAL VALIDATION
                if (isInternal)
                {
                    if (!new[] { "Location", "User", "Asset" }
                        .Contains(
                            destinationType,
                            StringComparer.OrdinalIgnoreCase))
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid internal destination type."
                        };
                    }

                    if (!int.TryParse(
                            Convert.ToString(checkout.destinationId),
                            out destinationId) ||
                        destinationId <= 0)
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid internal destination ID."
                        };
                    }
                }

                // EXTERNAL VALIDATION
                if (isExternal)
                {
                    if (string.Equals(
                        destinationType,
                        "Supplier",
                        StringComparison.OrdinalIgnoreCase))
                    {
                        destinationType = "Supplier";

                        int parsedVendorId;

                        if (!int.TryParse(
                                Convert.ToString(checkout.supplierId),
                                out parsedVendorId) ||
                            parsedVendorId <= 0)
                        {
                            return new
                            {
                                Success = false,
                                Message = "Select a valid supplier."
                            };
                        }

                        vendorId = parsedVendorId;
                    }
                    else if (string.Equals(
                        destinationType,
                        "Company",
                        StringComparison.OrdinalIgnoreCase))
                    {
                        destinationType = "Company";

                        companyCode =
                            Convert.ToString(checkout.companyId);

                        if (string.IsNullOrWhiteSpace(companyCode))
                        {
                            return new
                            {
                                Success = false,
                                Message = "Select a valid company."
                            };
                        }

                        companyCode = companyCode.Trim();
                    }
                    else
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid external destination type."
                        };
                    }

                    DateTime parsedDate;

                    if (!DateTime.TryParse(
                        Convert.ToString(checkout.expectedCheckinDate),
                        out parsedDate))
                    {
                        return new
                        {
                            Success = false,
                            Message = "Select an expected check-in date."
                        };
                    }

                    expectedCheckin = parsedDate.Date;
                }

                // VALIDATE BARCODE IDS
                HashSet<int> barcodeIds = new HashSet<int>();

                foreach (string barcode in checkout.barcodeIds)
                {
                    int parsedId;

                    if (!int.TryParse(barcode, out parsedId) ||
                        parsedId <= 0)
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid barcode: " + barcode
                        };
                    }

                    barcodeIds.Add(parsedId);
                }

                if (barcodeIds.Count == 0)
                {
                    return new
                    {
                        Success = false,
                        Message = "No valid assets selected."
                    };
                }

                conn = DBConnection.GetConnection();

                trans = conn.BeginTransaction(
                    IsolationLevel.Serializable);

                // RESOLVE BARCODE ID TO REAL ASSET ID
                HashSet<int> assetIds = new HashSet<int>();

                foreach (int barcodeId in barcodeIds)
                {
                    using (SqlCommand lookup =
                        new SqlCommand(
                            @"SELECT Id
                              FROM dbo.assets_master
                                   WITH (UPDLOCK, HOLDLOCK)
                              WHERE barcodeId = @BarcodeId
                                AND Status = 1",
                            conn,
                            trans))
                    {
                        lookup.Parameters.Add(
                            "@BarcodeId",
                            SqlDbType.Int
                        ).Value = barcodeId;

                        using (SqlDataReader reader =
                            lookup.ExecuteReader())
                        {
                            if (!reader.Read())
                            {
                                throw new InvalidOperationException(
                                    "Barcode " + barcodeId +
                                    " is not available for transfer.");
                            }

                            int assetId =
                                Convert.ToInt32(reader["Id"]);

                            if (reader.Read())
                            {
                                throw new InvalidOperationException(
                                    "Duplicate barcode in database: " +
                                    barcodeId);
                            }

                            assetIds.Add(assetId);
                        }
                    }
                }

                if (assetIds.Count != barcodeIds.Count)
                {
                    throw new InvalidOperationException(
                        "Multiple barcodes refer to the same asset.");
                }

                if (isInternal &&
                    destinationType.Equals(
                        "Asset",
                        StringComparison.OrdinalIgnoreCase) &&
                    assetIds.Contains(destinationId))
                {
                    throw new InvalidOperationException(
                        "Destination asset cannot be selected for transfer.");
                }

                // CREATE TVP
                DataTable assetTable = new DataTable();

                assetTable.Columns.Add(
                    "AssetID", typeof(int));

                foreach (int assetId in assetIds)
                {
                    assetTable.Rows.Add(assetId);
                }

                // GENERATE TRANSACTION TAG
                string tableName;
                string tagPrefix;

                if (isInternal)
                {
                    tableName = "InternalTrans";
                    tagPrefix = "AIL";
                }
                else if (string.Equals(destinationType, "Supplier", StringComparison.OrdinalIgnoreCase))
                {
                    tableName = "ExternalTransSupplier";
                    tagPrefix = "AES";
                }
                else if (string.Equals(
                    destinationType,
                    "Company",
                    StringComparison.OrdinalIgnoreCase
                    ))
                {
                    tableName = "ExternalTrans";
                    tagPrefix = "AEL";
                }
                else
                {
                    throw new InvalidOperationException("Invalid transfer destination type");
                }

                string tag = CommonHelper.GenerateNextTag(
                    conn,
                    trans,
                    tableName,
                    "Id_Tag",
                    tagPrefix
                );

                // REPLACE WITH YOUR AUTHENTICATED USER ID
                int userId = 0;

                int transactionId;

                using (SqlCommand cmd = new SqlCommand(
                    "dbo.SP_SaveCheckout", conn, trans))
                {
                    cmd.CommandType =
                        CommandType.StoredProcedure;

                    cmd.CommandTimeout = 60;

                    cmd.Parameters.Add(
                        "@Type", SqlDbType.Int
                    ).Value = isInternal ? 1 : 2;

                    cmd.Parameters.Add(
                        "@Tag", SqlDbType.NVarChar, 100
                    ).Value = tag;

                    cmd.Parameters.Add(
                        "@UserID", SqlDbType.Int
                    ).Value = userId;

                    cmd.Parameters.Add(
                        "@Status", SqlDbType.Int
                    ).Value = 0;

                    cmd.Parameters.Add(
                        "@DestinationType",
                        SqlDbType.NVarChar, 50
                    ).Value = destinationType;

                    cmd.Parameters.Add(
                        "@DestinationId", SqlDbType.Int
                    ).Value = isInternal
                        ? (object)destinationId
                        : DBNull.Value;

                    cmd.Parameters.Add(
                        "@VendorId", SqlDbType.Int
                    ).Value = vendorId.HasValue
                        ? (object)vendorId.Value
                        : DBNull.Value;

                    cmd.Parameters.Add(
                        "@CompanyCode", SqlDbType.NVarChar, 50
                    ).Value = string.IsNullOrEmpty(companyCode)
                        ? (object)DBNull.Value
                        : companyCode;

                    // INTERNAL -> NULL
                    // EXTERNAL -> USER SELECTED DATE
                    cmd.Parameters.Add(
                        "@ExpectedCheckin", SqlDbType.Date
                    ).Value = expectedCheckin.HasValue
                        ? (object)expectedCheckin.Value
                        : DBNull.Value;

                    cmd.Parameters.Add(
                        "@Comment", SqlDbType.NVarChar, 2000
                    ).Value = string.IsNullOrEmpty(checkout.note)
                        ? (object)DBNull.Value
                        : checkout.note;

                    SqlParameter assetParameter =
                        cmd.Parameters.Add(
                            "@AssetIds",
                            SqlDbType.Structured);

                    assetParameter.TypeName = "dbo.AssetIdList";
                    assetParameter.Value = assetTable;

                    SqlParameter output =
                        cmd.Parameters.Add(
                            "@TransactionId",
                            SqlDbType.Int);

                    output.Direction =
                        ParameterDirection.Output;

                    cmd.ExecuteNonQuery();

                    transactionId =
                        Convert.ToInt32(output.Value);
                }


                if (isInternal &&
     destinationType.Equals(
         "Location",
         StringComparison.OrdinalIgnoreCase))
                {
                    // Verify that selected location exists
                    using (SqlCommand checkCmd = new SqlCommand(
                        @"SELECT COUNT(*)
          FROM dbo.Location
          WHERE Id = @LocationId",
                        conn, trans))
                    {
                        checkCmd.Parameters.Add(
                            "@LocationId",
                            SqlDbType.Int
                        ).Value = destinationId;

                        int locationCount =
                            Convert.ToInt32(checkCmd.ExecuteScalar());

                        if (locationCount != 1)
                        {
                            throw new InvalidOperationException(
                                "Selected location does not exist."
                            );
                        }
                    }

                    // Update all selected assets using their actual IDs
                    string updateSql = @"
                            UPDATE a
                            SET a.LocationID = @LocationId
                            FROM dbo.assets_master AS a
                            INNER JOIN @AssetIds AS ids
                            ON a.Id = ids.AssetID;
                            ";

                    using (SqlCommand updateCmd =
                        new SqlCommand(updateSql, conn, trans))
                    {
                        updateCmd.Parameters.Add(
                            "@LocationId",
                            SqlDbType.Int
                        ).Value = destinationId;

                        SqlParameter assetParam =
                            updateCmd.Parameters.Add(
                                "@AssetIds",
                                SqlDbType.Structured);

                        assetParam.TypeName = "dbo.AssetIdList";
                        assetParam.Value = assetTable;

                        int affectedRows =
                            updateCmd.ExecuteNonQuery();

                        if (affectedRows != assetIds.Count)
                        {
                            throw new InvalidOperationException(
                                "Location update failed. Expected: " +
                                assetIds.Count +
                                ", Updated: " + affectedRows
                            );
                        }

                        Logger(
                            "Internal location successfully updated. " +
                            "Location ID: " + destinationId +
                            " | Updated Assets: " + affectedRows
                        );
                    }
                }

                // Commit the transfer and asset updates together
                trans.Commit();
                trans = null;

                Logger(
                    "Transfer saved: " + tag +
                    " | " + checkoutType +
                    " | Assets: " + assetIds.Count);

                return new
                {
                    Success = true,
                    Message =
                        checkoutType + " " +
                        destinationType +
                        " transfer saved successfully!",

                    TransactionId = transactionId,
                    TransactionTag = tag,
                    ReceivedCount = assetIds.Count
                };
            }
            catch (Exception ex)
            {
                try
                {
                    if (trans != null)
                        trans.Rollback();
                }
                catch (Exception rollbackEx)
                {
                    Logger("Rollback Error: " + rollbackEx);
                }

                Logger("SaveCheckout Error: " + ex);

                return new
                {
                    Success = false,
                    Message = ex is InvalidOperationException
                        ? ex.Message
                        : "Unable to save transfer."
                };
            }
            finally
            {
                if (trans != null)
                    trans.Dispose();

                DBConnection.CloseConnection(conn);
            }
        }

        // APPLY CONDITION (postback)
        // Failure -> SweetAlert.Show error popup
        // Success -> SweetAlert success popup (via showAlert in ManageTransfer.js)
        protected void btnApplyCondition_Click(object sender, EventArgs e)
        {
            try
            {
                string barcodeText = hfConditionBarcodeIds.Value;

                if (string.IsNullOrWhiteSpace(barcodeText))
                {
                    //SweetAlert.Show(this, "Error", "No Assets Selected", "error");
                    return;
                }

                List<int> barcodeIds = new List<int>();

                foreach (string value in barcodeText.Split(','))
                {
                    int barcodeId;

                    if (!int.TryParse(value.Trim(), out barcodeId) || barcodeId <= 0)
                    {
                        //SweetAlert.Show(this, "Error", "Invalid barcode ID", "error");
                        return;
                    }

                    barcodeIds.Add(barcodeId);
                }

                barcodeIds = barcodeIds.Distinct().ToList();

                int conditionId;

                if (!int.TryParse(DPCondition.SelectedValue, out conditionId) || conditionId <= 0)
                {
                    //SweetAlert.Show(this, "Error", "Invalid Condition Selected", "error");
                    return;
                }

                string conditionText = DPCondition.SelectedItem.Text;

                using (SqlConnection conn = DBConnection.GetConnection())
                {
                    using (SqlTransaction transaction = conn.BeginTransaction())
                    {
                        try
                        {
                            foreach (int barcodeId in barcodeIds)
                            {
                                string sql = @"UPDATE dbo.assets_master SET [condition] = @ConditionId
                                            WHERE [barcodeId] = @BarcodeId";

                                using (SqlCommand cmd = new SqlCommand(sql, conn, transaction))
                                {
                                    cmd.Parameters.Add("@ConditionId", SqlDbType.Int).Value = conditionId;
                                    cmd.Parameters.Add("@BarcodeId", SqlDbType.Int).Value = barcodeId;

                                    int affected = cmd.ExecuteNonQuery();

                                    // Previously this only showed an alert and still committed.
                                    // Now it rolls everything back and reports one clear error.
                                    if (affected != 1)
                                    {
                                        Logger("Error in Condition update: " + barcodeId);

                                        throw new InvalidOperationException(
                                            "Asset not found or could not be updated (barcode " +
                                            barcodeId + ").");
                                    }
                                }
                            }
                            transaction.Commit();
                        }

                        catch (Exception)
                        {
                            transaction.Rollback();
                            throw;
                        }
                    }
                }

                var serializer = new JavaScriptSerializer();

                string idsJson = serializer.Serialize(
                    barcodeIds.Select(x => x.ToString()).ToArray());

                string conditionJson = serializer.Serialize(conditionText);

                string messageJson = serializer.Serialize(
                    barcodeIds.Count + " asset condition(s) updated successfully.");

                string script = $@"
            window.addEventListener('load', function() {{

                const ids = {idsJson};
                const condition = {conditionJson};
                const message = {messageJson};

                ids.forEach(function(id) {{

                    const asset = gridAssets.get(id);

                    if (asset) {{
                        asset.Condition = condition;
                    }}

                }});

                renderGrid();
                closeConditionModal();

                notify(message);
                showAlert('Success', message, 'success', focusScanner);

            }});
        ";

                ClientScript.RegisterStartupScript(
                    GetType(),
                    "ConditionUpdated",
                    script,
                    true);
            }
            catch (InvalidOperationException ex)
            {
                Logger("Error in Condition: " + ex.ToString());

                //SweetAlert.Show(this, "Error", ex.Message, "error");
            }
            catch (Exception ex)
            {
                Logger("Error in Condition: " + ex.ToString());

                //SweetAlert.Show(this, "Error", "Unable to update Asset Conditions", "error");
            }
        }

        // LOAD COMPANY DROPDOWN
        private void LoadCompanies()
        {
            try
            {
                string sql =
                    "SELECT UPPER(Alias) AS CompanyName, " +
                    "CompanyCode " +
                    "FROM [MerchandisingHO].[dbo].[Company] " +
                    "WHERE CompanyCode NOT IN " +
                    "('EMB','MST','TCS','SN','RCS')";

                DropDown drop = new DropDown
                {
                    sql = sql,
                    dropDown = externalCompany,
                    dataTextField = "CompanyName",
                    dataValueField = "CompanyCode",
                    listHeading = "-- Select Company --"
                };

                LoadDropDown loader = new LoadDropDown();
                loader.LoadDropDownAll(drop);
            }
            catch (Exception ex)
            {
                Logger("LoadCompanies Error: " + ex);
            }
        }

        // LOAD LOCATION DROPDOWN
        private void LoadLocations()
        {
            try
            {
                string sql =
                    "EXECUTE SP_GetLocation " +
                    "@Type = 1, @CompanyCode = 'SP'";

                DropDown drop = new DropDown
                {
                    sql = sql,
                    dropDown = checkoutLocation,
                    dataTextField = "locationName",
                    dataValueField = "Id",
                    listHeading = "-- Select Location --"
                };

                LoadDropDown loader = new LoadDropDown();
                loader.LoadDropDownAll(drop);
            }
            catch (Exception ex)
            {
                Logger("LoadLocations Error: " + ex);
                throw new ApplicationException(
                    "Error loading locations.");
            }
        }

        // LOAD SUPPLIER DROPDOWN
        private void LoadVendors()
        {
            try
            {
                string sql =
                    "EXECUTE SP_GetVendor @Type = 1";

                DropDown drop = new DropDown
                {
                    sql = sql,
                    dropDown = externalSupplier,
                    dataTextField = "VendorName",
                    dataValueField = "VendorId",
                    listHeading = "-- Select Vendor / Supplier --"
                };

                LoadDropDown loader = new LoadDropDown();
                loader.LoadDropDownAll(drop);
            }
            catch (Exception ex)
            {
                Logger("LoadVendors Error: " + ex);
                throw new ApplicationException(
                    "Error loading vendors.");
            }
        }

        private void LoadCondition()
        {
            try
            {
                string query = "SP_ManageCondition";
                using (SqlConnection conn = DBConnection.GetConnection())
                {
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        DropDown drop = new DropDown
                        {
                            sql = query,
                            dropDown = DPCondition,
                            dataTextField = "Condition",
                            dataValueField = "Id",
                            listHeading = "-- Select Condition --"
                        };

                        LoadDropDown loader = new LoadDropDown();
                        loader.LoadDropDownAll(drop);
                    }
                }
            }

            catch (Exception ex)
            {
                Logger("Error in Condition: " + ex.ToString());

            }
        }
    }
}