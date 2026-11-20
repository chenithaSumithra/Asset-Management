
using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Permissions;
using System.Web;

namespace Asset_Management.Helpers
{
    public class CommonHelper
    {
        public static string GenerateNextTag(
            SqlConnection conn,
            SqlTransaction transaction,
            string tableName,
            string columnName,
            string prefix)
        {
            // Validate allowed tables and columns
            if (tableName == "InternalTrans" &&
                columnName == "Id_Tag")
            {
                tableName = "[dbo].[InternalTrans]";
                columnName = "[Id_Tag]";
            }
            else if (tableName == "ExternalTrans" &&
                     columnName == "Id_Tag")
            {
                tableName = "[dbo].[ExternalTrans]";
                columnName = "[Id_Tag]";
            }
            else if (tableName == "ExternalTransSupplier" &&
                     columnName == "Id_Tag")
            {
                tableName = "[dbo].[ExternalTransSupplier]";
                columnName = "[Id_Tag]";
            }
            else
            {
                throw new ArgumentException(
                    "Invalid table or column.");
            }

            if (string.IsNullOrWhiteSpace(prefix))
            {
                throw new ArgumentException(
                    "Prefix is required.");
            }                                                   

            prefix = prefix.Trim().ToUpperInvariant();

            string sql = @"
                SELECT ISNULL(
                    MAX(
                        TRY_CONVERT(
                            INT,
                            SUBSTRING(
                                " + columnName + @",
                                LEN(@Prefix) + 1,
                                50
                            )
                        )
                    ), 0)
                FROM " + tableName + @" WITH (TABLOCKX, HOLDLOCK)
                WHERE LEFT(" + columnName + @",
                           LEN(@Prefix)) = @Prefix
                  AND TRY_CONVERT(
                          INT,
                          SUBSTRING(
                              " + columnName + @",
                              LEN(@Prefix) + 1,
                              50
                          )
                      ) IS NOT NULL;";

            using (SqlCommand cmd = new SqlCommand(
                sql, conn, transaction))
            {
                cmd.Parameters.Add(
                    "@Prefix",
                    SqlDbType.NVarChar,
                    50
                ).Value = prefix;

                int lastNumber =
                    Convert.ToInt32(cmd.ExecuteScalar());

                int nextNumber = checked(lastNumber + 1);

                string tag = prefix +
                             nextNumber.ToString("D7");

                Logger.Lo("Generated Tag: " + tag);

                return tag;
            }
        }
    }
}
