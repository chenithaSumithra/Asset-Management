using Asset_Management.DAO;
using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace Asset_Management.Helpers
{
    public class LoadDropDown 
    {
        public void LoadDropDownAll(DropDown drop)
        {
          try
            {
                drop.dropDown.Items.Clear();

                drop.dropDown.DataSource = DataManagement.GetData(drop.sql);
                drop.dropDown.DataTextField = drop.dataTextField;
                drop.dropDown.DataValueField = drop.dataValueField;
                drop.dropDown.DataBind();
            
                drop.dropDown.Items.Insert(0, new ListItem(drop.listHeading, "0"));
                drop.dropDown.ClearSelection();
                drop.dropDown.SelectedIndex = 0;
            }

          catch (Exception ex)
             {

                Logger.Lo("Errror in drop down: " + drop.dropDown + " : " + ex.ToString());
                throw new ApplicationException("An error occurred while loading the dropdown.", ex);

             }
        }
    }
}

