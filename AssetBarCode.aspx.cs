
using Asset_Management.Connection;
using Asset_Management.DAO;
using Asset_Management.Helpers;
using Asset_Management.Models;
using Microsoft.Owin.Logging;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Drawing.Printing;
using System.Linq;
using System.Security.Cryptography.Xml;
using System.Web.Services;
using System.Web.Services.Description;
using System.Web.UI;

namespace Asset_Management
{
    public partial class AssetBarCode : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if(!IsPostBack)
            {
                LoadTotalAssetsCount();
                LoadCompanies();
                LoadLocations();
                LoadVendors();
            }
        }

        private void LoadTotalAssetsCount()
        {
            try
            {
                using(SqlConnection conn = DBConnection.GetConnection())
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

        [WebMethod]
        public static AssetLookupResponse GetAssetByBarcode(int barcodeId)
        {
            AssetLookupResponse result = new AssetLookupResponse();
            SqlConnection conn = null;

            try
            {
                if (barcodeId <= 0)
                {
                    //result.Success = false;
                    //result.Message = "Invalid barcode ID.";
                    //ScriptManager.RegisterStartupScript(this, this.GetType(), "alert", "alert('Invalid barcode ID.');", true);
                }

                // Open connection using Connection helper.
                conn = DBConnection.GetConnection();

                using (SqlCommand cmd = new SqlCommand(
                    "SP_GetAssetByBarCode", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;

                    cmd.Parameters.Add(
                        "@barcodeId", SqlDbType.Int
                    ).Value = barcodeId;

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            AssetDetails asset = new AssetDetails();

                            asset.BarcodeId = barcodeId.ToString();
                            asset.AssetName = ReadValue(reader, "AssetName");
                            asset.Serial = ReadValue(reader, "Serial");
                            asset.MachineNo = ReadValue(reader, "MachineNo");
                            asset.Model = ReadValue(reader, "Model");
                            asset.Model_No = ReadValue(reader, "Model_No");

                            //result.Asset = asset;
                            //result.Success = true;
                            //result.Message = "Asset found.";
                        }
                        else
                        {
                            //result.Success = false;
                            //result.Message =
                            //    "No asset found for barcode: " + barcodeId;
                            //ScriptManager.RegisterStartupScript(this, this.GetType(), "alert", "alert('No asset found for barcode: " + barcodeId + "');", true);
                        }
                    }
                }
            }
            catch (Exception)
            {
                // Log the exception on the server if logging is configured.
                //result.Success = false;
                //result.Message = "Unable to retrieve asset details.";
                //ScriptManager.RegisterStartupScript(this, this.GetType(), "alert", "alert('Unable to retrieve asset details.');", true);
            }
            finally
            {
                // Close and dispose connection.
                DBConnection.CloseConnection(conn);
            }

            return result;
        }

        private static string ReadValue(
            SqlDataReader reader, string columnName)
        {
            int index = reader.GetOrdinal(columnName);

            if (reader.IsDBNull(index))
                return "";

            return Convert.ToString(reader.GetValue(index));
        }
        


        private static void Logger(string message)
        {
            System.Diagnostics.Debug.WriteLine(message);
        }



        [WebMethod(EnableSession = true)]
        public static object SaveCheckout(CheckoutRequest checkout)
        {
            SqlConnection conn = null;
            SqlTransaction trans = null;

            try
            {
                if (checkout?.barcodeIds == null ||
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
                    checkoutType, "Internal",
                    StringComparison.OrdinalIgnoreCase);

                bool isExternal = string.Equals(
                    checkoutType, "External",
                    StringComparison.OrdinalIgnoreCase);

                if (!isInternal && !isExternal)
                {
                    return new
                    {
                        Success = false,
                        Message = "Invalid checkout type."
                    };
                }

                string destinationType =
                    (checkout.destinationType ?? "").Trim();

                int destinationId = 0;
                int? vendorId = null;
                string companyCode = null;
                DateTime? expectedCheckin = null;

                // INTERNAL CHECKOUT VALIDATION
                if (isInternal)
                {
                    if (!new[] { "Location", "User", "Asset" }
                        .Contains(destinationType,
                            StringComparer.OrdinalIgnoreCase))
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid internal checkout type."
                        };
                    }

                    if (!int.TryParse(
                        Convert.ToString(checkout.destinationId),
                        out destinationId) || destinationId <= 0)
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid internal destination ID."
                        };
                    }
                }

                // EXTERNAL CHECKOUT VALIDATION
                if (isExternal)
                {
                    if (string.Equals(
                        destinationType, "Supplier",
                        StringComparison.OrdinalIgnoreCase))
                    {
                        destinationType = "Supplier";

                        int parsedVendorId;

                        if (!int.TryParse(
                            Convert.ToString(checkout.supplierId),
                            out parsedVendorId) || parsedVendorId <= 0)
                        {
                            return new
                            {
                                Success = false,
                                Message = "Please select a valid supplier."
                            };
                        }

                        vendorId = parsedVendorId;
                    }
                    else if (string.Equals(
                        destinationType, "Company",
                        StringComparison.OrdinalIgnoreCase))
                    {
                        destinationType = "Company";

                        companyCode =
                            Convert.ToString(checkout.companyId)?.Trim();

                        if (string.IsNullOrWhiteSpace(companyCode))
                        {
                            return new
                            {
                                Success = false,
                                Message = "Please select a valid company."
                            };
                        }
                    }
                    else
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid external checkout type."
                        };
                    }

                    if (string.IsNullOrWhiteSpace(
                        Convert.ToString(checkout.expectedCheckinDate)) ||
                        !DateTime.TryParse(
                            Convert.ToString(checkout.expectedCheckinDate),
                            out DateTime parsedDate))
                    {
                        return new
                        {
                            Success = false,
                            Message = "Please select a valid expected check-in date."
                        };
                    }

                    expectedCheckin = parsedDate.Date;
                }

                // VALIDATE ASSETS
                var assetIds = new HashSet<int>();

                foreach (string barcode in checkout.barcodeIds)
                {
                    if (!int.TryParse(barcode, out int id) || id <= 0)
                    {
                        return new
                        {
                            Success = false,
                            Message = "Invalid barcode: " + barcode
                        };
                    }

                    assetIds.Add(id);
                }

                if (isInternal &&
                    destinationType.Equals("Asset",
                        StringComparison.OrdinalIgnoreCase) &&
                    assetIds.Contains(destinationId))
                {
                    return new
                    {
                        Success = false,
                        Message = "Destination asset cannot be a selected asset."
                    };
                }

                // PREPARE ASSET TABLE
                DataTable assets = new DataTable();
                assets.Columns.Add("AssetID", typeof(int));

                foreach (int id in assetIds)
                {
                    assets.Rows.Add(id);
                }

                conn = DBConnection.GetConnection();

                trans = conn.BeginTransaction(
                    IsolationLevel.Serializable);

                string tableName;
                string tagPrefix;

                if(isInternal)
                {
                    tableName = "InternalTrans";
                    tagPrefix = "AIL";
                }
                else
                {
                    tableName = "ExternalTrans";

                    if(string.Equals(
                        destinationType,
                        "Supplier",
                        StringComparison.OrdinalIgnoreCase))
                    {
                        tagPrefix = "AES";
                    }
                    else
                    {
                        tagPrefix = "AEL";
                    }
                }

                string tag = CommonHelper.GenerateNextTag(
                    conn,
                    trans,
                    tableName,
                    "Id_Tag",
                    tagPrefix
                );

                int userId = 0;
                int transId;

                using (SqlCommand cmd = new SqlCommand(
                    "dbo.SP_SaveCheckout", conn, trans))
                {
                    cmd.CommandType = CommandType.StoredProcedure;

                    // COMMON PARAMETERS
                    cmd.Parameters.Add(
                        "@Type", SqlDbType.Int).Value =
                            isInternal ? 1 : 2;

                    cmd.Parameters.Add(
                        "@Tag", SqlDbType.NVarChar, 100).Value = tag;

                    cmd.Parameters.Add(
                        "@UserID", SqlDbType.Int).Value = userId;

                    cmd.Parameters.Add(
                        "@Status", SqlDbType.Int).Value = 0;

                    cmd.Parameters.Add(
                        "@DestinationType",
                        SqlDbType.NVarChar, 50).Value = destinationType;

                    cmd.Parameters.Add(
                        "@DestinationId", SqlDbType.Int).Value =
                            isInternal ? (object)destinationId : DBNull.Value;

                    // EXTERNAL PARAMETERS
                    cmd.Parameters.Add(
                        "@VendorId", SqlDbType.Int).Value =
                            vendorId.HasValue
                                ? (object)vendorId.Value
                                : DBNull.Value;

                    cmd.Parameters.Add(
                        "@CompanyCode", SqlDbType.NVarChar, 50).Value =
                            (object)companyCode ?? DBNull.Value;

                    cmd.Parameters.Add(
                        "@ExpectedCheckin", SqlDbType.Date).Value =
                            expectedCheckin.HasValue
                                ? (object)expectedCheckin.Value
                                : DBNull.Value;

                    cmd.Parameters.Add(
                        "@Comment", SqlDbType.NVarChar, 2000).Value =
                            (object)checkout.note ?? DBNull.Value;

                    // ASSET IDS
                    var assetParam = cmd.Parameters.Add(
                        "@AssetIds", SqlDbType.Structured);

                    assetParam.TypeName = "dbo.AssetIdList";
                    assetParam.Value = assets;

                    // OUTPUT
                    var output = cmd.Parameters.Add(
                        "@TransactionId", SqlDbType.Int);

                    output.Direction = ParameterDirection.Output;

                    cmd.ExecuteNonQuery();

                    transId = Convert.ToInt32(output.Value);
                }

                trans.Commit();
                trans = null;

                Logger(
                    $"{checkoutType} checkout saved: " +
                    $"{tag} | {destinationType}"
                );

                return new
                {
                    Success = true,
                    Message = $"{checkoutType} {destinationType} checkout saved successfully!",
                    TransactionId = transId,
                    TransactionTag = tag,
                    CheckoutType = checkoutType,
                    DestinationType = destinationType,
                    DestinationId = isInternal
                        ? Convert.ToString(destinationId)
                        : destinationType == "Supplier"
                            ? Convert.ToString(vendorId)
                            : companyCode,
                    ReceivedCount = assetIds.Count
                };
            }
            catch (Exception ex)
            {
                try
                {
                    trans?.Rollback();
                }
                catch (Exception rollbackEx)
                {
                    Logger("Rollback Error: " + rollbackEx);
                }

                Logger("SaveCheckout Error: " + ex);

                return new
                {
                    Success = false,
                    Message = "Unable to save checkout."
                };
            }
            finally
            {
                trans?.Dispose();
                DBConnection.CloseConnection(conn);
            }
        }



        [WebMethod]
        public static object SearchAssets(string search)
        {
            List<object> assets = new List<object>();
            SqlConnection conn = null;

            try
            {
                if(string.IsNullOrWhiteSpace(search))
                {
                    return new
                    {
                        Success = true,
                        Assets = assets
                    };
                }

                search = search.Trim();

                if(search.Length > 255)
                {
                    return new
                    {
                        Success = false,
                        Message = "Search mus not exceed 255 parameters.",
                        Assets = assets
                    };
                }

                Logger("Searching Assets: " + search);

                conn = DBConnection.GetConnection();

                using (SqlCommand cmd = new SqlCommand ("dbo.getAllAssets", conn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandTimeout = 30;

                    cmd.Parameters.Add("@Type", SqlDbType.Int).Value = 2;

                    cmd.Parameters.Add(
                        "@Search",
                        SqlDbType.NVarChar,
                        255
                        ).Value = search;

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            assets.Add(new
                            {
                                BarcodeId = ReadValue(reader, "barcodeId"),
                                AssetName = ReadValue(reader, "AssetName"),
                                Serial = ReadValue(reader, "Serial"),
                                MachineNo = ReadValue(reader, "MachineNo"),
                                Model = ReadValue(reader, "Model"),
                                Model_No = ReadValue(reader, "Model_No"),
                                Company = ReadValue(reader, "Company"),
                                Manufacturer = ReadValue(reader, "Manufacturer"),
                                SubCategory = ReadValue(reader, "SubCategory"),
                                Location = ReadValue(reader, "Location"),
                                Status = ReadValue(reader, "Status")
                            });

                            if (assets.Count >= 30)
                                break;
                        }
                    }
                }

                Logger("Asset search results: " + assets.Count);

                return new
                {
                    Success = true,
                    Assets = assets
                };
            }

            catch(Exception ex)
            {
                Logger("SearchAssets Error: " + ex.ToString());

                return new
                {
                    Success = false,
                    Message = "Unable to search Asses",
                    Assets = assets
                };
            }
            
            finally
            {
                DBConnection.CloseConnection(conn);
            }
        }

        private void LoadCompanies()
        {
            try
            {
                string sql = "SELECT UPPER(Alias) AS CompanyName, CompanyCode FROM [MerchandisingHO].[dbo].[Company] " +
                         "WHERE Companycode NOT IN ('EMB', 'MST', 'TCS', 'SN', 'RCS')";

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
            catch(Exception ex)
            {
                Logger("Error loading companies: " + ex);
            }

        }

        private void LoadLocations()
        {
            try
            {
                string companyCode = "SP";
                string sql = "EXECUTE SP_GetLocation " + "@Type = 1, " + "@CompanyCode = " + companyCode;

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
                Logger("Error loading locations: " + ex.ToString());
                throw new ApplicationException("Error in Loading Locations");
                
            }
        }

        private void LoadVendors()
        {
            try
            {
                string sql = "EXECUTE SP_GetVendor @Type = 1";

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
            catch(Exception ex)
            {
                Logger("Error Loading LoadVendors: " + ex.ToString());
                throw new ApplicationException("Error in Loading Vendors/Suuplier");
            }
        }
    }
}
