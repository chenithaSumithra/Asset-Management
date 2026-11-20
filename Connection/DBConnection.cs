using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace Asset_Management.Connection
{
    public class DBConnection 
    {
        private static readonly string connectionString = ConfigurationManager.ConnectionStrings["Connection"].ConnectionString;

        public static SqlConnection GetConnection()
        {
            SqlConnection conn = new SqlConnection(connectionString);
            conn.Open();

            return conn;
        }

        public static void  CloseConnection(SqlConnection conn)
        {
            if(conn != null && conn.State != System.Data.ConnectionState.Closed)
            {
                conn.Close();
            }
        }
    }
}