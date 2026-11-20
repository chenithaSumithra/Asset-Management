using Asset_Management.Connection;
using Asset_Management.Helpers;
using Microsoft.AspNet.SignalR;
using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;

namespace Asset_Management.DAL
{
    public class FormAuthenticationDAL 
    {
       public static void checkFormPage(Page page, int formID, int userID)
        {
            bool result = false;

            if(formID <= 0 || userID <= 0)
            {
                //SweetAlert.ShowAndClose(page, "Denied!", "You do not have permissions to access this page", "error");
              
                return;
            }

            try
            {
                using(SqlConnection conn = DBConnection.GetConnection())
                {
                   using (SqlCommand cmd = new SqlCommand("dbo.SP_FormAccess", conn))
                   {
                        cmd.CommandType = System.Data.CommandType.StoredProcedure;

                        cmd.Parameters.Add("@UserId", System.Data.SqlDbType.Int).Value = userID;
                        cmd.Parameters.Add("@FormId", System.Data.SqlDbType.Int).Value = formID;

                        using(SqlDataReader dr = cmd.ExecuteReader())
                        {
                            if(dr.Read())
                            {
                                result = true;
                            }
                        }

                        if (!result)
                        {
                            //SweetAlert.ShowAndClose(page, "Access Denied!", "You dont have permissions to this Page", "error");

                            ScriptManager.RegisterStartupScript(
                                page,
                                page.GetType(),
                                  "RedirectAfterDelay",
                                @"
                               setTimeout(function () {
                                window.history.back();
                               }, 2000);",
                                true);
                        }
                   }
                }
            }

            catch (Exception ex)
            {
                //SweetAlert.Show(page, "Error", "An error occured when checking form access", "error");
                page.Response.Redirect("~/Home.aspx", false);
            }
       }


        public static bool HasFormAccess(int formID, int userID)
        {
            if (formID <= 0 || userID <= 0)
                return false;

            try
            {
                using(SqlConnection conn = DBConnection.GetConnection())
                {
                    using(SqlCommand cmd = new SqlCommand("dbo.SP_FormAccess", conn))
                    {
                        cmd.Parameters.Add("@UserId", System.Data.SqlDbType.Int).Value = userID;
                        cmd.Parameters.Add("@FormId", System.Data.SqlDbType.Int).Value = formID;

                        using(SqlDataReader dr = cmd.ExecuteReader())
                        {
                            return dr.Read();
                        }
                    }
                }
            }

            catch (Exception ex)
            {
                Logger.Lo("Error in Form Authentication DAL: " + ex.ToString());
                return false;
                throw;
            }
        }
    }
}