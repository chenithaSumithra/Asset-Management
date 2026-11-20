using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;

namespace Asset_Management.Helpers
{
    public class SessionHelper 
    {
        public static void SetSessions(string username, string userid)
        {
            try
            {
                if(string.IsNullOrEmpty(username) || string.IsNullOrEmpty(userid))
                {
                    HttpContext.Current.Session.Clear();
                    throw new Exception("Username or User Id is empty");
                }

                HttpContext.Current.Session["username"] = username;
                HttpContext.Current.Session["userid"] = userid;

                Logger.Lo($"[SessionHelper] Session set - Username: {username}, UserID: {userid}");
            }

            catch (Exception ex)
            {
                Logger.Lo($"[SessionHelper] Error setting session: {ex.Message}");

                if(HttpContext.Current?.Handler is Page page)
                {
                    //SweetAlert.Show(page, "Session Error", "Failed to set user session. Please try again", "error");
                }

                HttpContext.Current?.Response.Redirect("~/Authentication/Login.aspx", false);
                HttpContext.Current?.ApplicationInstance.CompleteRequest();
            }
        }
       
        public static int GetUserId()
        {
            try
            {
                if (HttpContext.Current?.Session != null)
                {
                    var userId = HttpContext.Current.Session["userid"];

                    if(userId != null)
                    {
                        int id = Convert.ToInt32(userId);
                        Logger.Lo($"[SessionHelper] UserID retrieved: {id}");
                        return id;
                    }
                    else
                    {
                        string returnURL = HttpContext.Current.Request.Url.PathAndQuery;
                        HttpContext.Current.Response.Redirect("~/Authentication/Login.aspx?ReturnUrl=" + returnURL, false);
                        HttpContext.Current.ApplicationInstance.CompleteRequest();
                    }
                }
            }

            catch(Exception ex)
            {
                Logger.Lo($"[SessionHelper] Error getting UserID: {ex.Message}");
            }

            return 0;
        }

        public static string GetUserName()
        {
            try
            {
                Page page = new Page();
                if(HttpContext.Current?.Session != null)
                {
                    var username = HttpContext.Current.Session["username"];

                    if(username != null)
                    {
                        string name = Convert.ToString(username);
                        Logger.Lo($"[SessionHelper] Username retrieved: {name}");
                        return name;
                    }
                    else
                    {
                        string returnPath = "~/Authetication/Login.aspx";
                        //SweetAlert.Show(page, "error", "Session is null. Please Login First", "error");
                        Logger.Lo("[SessionHelper] Session['username'] is null");
                        return returnPath;
                    }
                }
            }
            catch(Exception ex)
            {
                Logger.Lo($"[SessionHelper] Error getting Username: {ex.Message}");
            }
            return null;
        }


        public static bool IsAuthenticated()
        {
            return HttpContext.Current?.Session?["userid"] != null;
        }
    }
}