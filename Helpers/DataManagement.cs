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
    public class DataManagement 
    {
       public static DataTable GetData(string query)
        {
            SqlConnection conn = DBConnection.GetConnection();

            if(conn.State.ToString() == "Closed")
            {
                conn.Open();
            }

            string strConString = conn.ConnectionString;

            using(conn = new SqlConnection(strConString))
            {
                using (SqlCommand cmd = new SqlCommand())
                {
                    cmd.CommandText = query;
                    using (SqlDataAdapter sda = new SqlDataAdapter())
                    {
                        cmd.Connection = conn;
                        sda.SelectCommand = cmd;
                        
                        using (DataSet ds = new DataSet())
                        {
                            DataTable dt = new DataTable();
                            sda.Fill(dt);
                            return dt;
                        }
                    }
                }
            }
        }
    }
}