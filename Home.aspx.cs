using Asset_Management.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Asset_Management
{
    public partial class Home : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            int user = SessionHelper.GetUserId();

            if( user == 0)
            {
                //SweetAlert.Show(this, "Error", "Session is null", "error");
            }
            else
            {
                //SweetAlert.Show(this, "Success", "Session is not null ", "error");
            }
        }
    }
}