using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace Asset_Management.DAO
{
    public class DropDown 
    {
        public string sql { get; set; }
        public DropDownList dropDown { get; set; }
        public string dropDownName { get; set; }
        public string dataTextField { get; set; }
        public string dataValueField { get; set; }
        public string listHeading { get; set; }
    }
}