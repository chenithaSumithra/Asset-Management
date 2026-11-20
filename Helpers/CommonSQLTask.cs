using Asset_Management.Connection;
using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace Asset_Management.Helpers
{
    public class CommonSQLTask
    {
        public bool AddLoginLog(int userid, int pageid, int type)
        {


            string sql = "[MerchandisingHO].[dbo].[sp_OperationAPMaSLogin] @UserID, @PageID, @Type";

            try
            {
                // ✅ Fresh connection per call — avoids stale/closed connection bugs
                using (SqlConnection conn = DBConnection.GetConnection())
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.CommandType = CommandType.Text;

                    cmd.Parameters.Add(new SqlParameter("@UserID", SqlDbType.Int) { Value = userid });
                    cmd.Parameters.Add(new SqlParameter("@PageID", SqlDbType.Int) { Value = pageid });
                    cmd.Parameters.Add(new SqlParameter("@Type", SqlDbType.Int) { Value = type });

                    System.Diagnostics.Debug.WriteLine("[AddLoginLog] Executing sp_OperationAPMaSLogin...");
                    cmd.ExecuteNonQuery();
                    System.Diagnostics.Debug.WriteLine("[AddLoginLog] Executed successfully.");

                    // ✅ Bug fix: was returning false here unconditionally
                    return true;
                }
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine($"[AddLoginLog][SQL ERROR] {ex.Message}\n{ex}");
                throw new Exception("Login log error: " + ex.Message, ex);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[AddLoginLog][ERROR] {ex.Message}\n{ex}");
                throw;
            }
        }
    }
}