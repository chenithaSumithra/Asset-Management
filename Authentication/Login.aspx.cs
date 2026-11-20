using Asset_Management.Connection;
using Asset_Management.Helpers;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Asset_Management.Authentication
{
    public partial class Login : System.Web.UI.Page
    {
        CommonSQLTask CT = new CommonSQLTask();

        protected void Page_Load(object sender, EventArgs e)
        {
            // If already authenticated, redirect away from login page
            if (User.Identity.IsAuthenticated)
            {

                Response.Redirect("~/Home.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        protected void btnLogin_Click(object sender, EventArgs e)
        {
            string username = txtLoginUsername.Text.Trim();
            string password = txtLoginPassword.Text;

            // ── Basic client-side guard ──────────────────────────────────────
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {

                //SweetAlert.Show(this, "Validation", "Username and password are required.", "warning");
                return;
            }



            try
            {
                // ── Encrypt password ─────────────────────────────────────────
                string encryptedPassword;
                try
                {
                    encryptedPassword = Encrypter.Encrypt(password, Encrypter.CON_ENCRYPT_KEY);

                }
                catch (Exception encEx)
                {

                    //SweetAlert.Show(this, "Error", "An internal error occurred. Please try again.", "error");
                    return;
                }

                // ── Open DB connection ───────────────────────────────────────
                using (SqlConnection conn = DBConnection.GetConnection())
                {

                    System.Threading.Thread.Sleep(300); // Retain original delay

                    // ── Parameterized stored procedure call (SQL-injection safe) ──
                    using (SqlCommand cmd = new SqlCommand("[MerchandisingHO].[dbo].[SP_Login]", conn))
                    {
                        cmd.CommandType = System.Data.CommandType.StoredProcedure;
                        cmd.Parameters.AddWithValue("@Username", username);
                        cmd.Parameters.AddWithValue("@Password", encryptedPassword);

                        System.Diagnostics.Debug.WriteLine("[Login] Executing SP_Login...");

                        SqlDataReader sdr = null;
                        try
                        {
                            sdr = cmd.ExecuteReader();

                        }
                        catch (SqlException sqlEx)
                        {
                            System.Diagnostics.Debug.WriteLine($"[Login][SQL ERROR] SP_Login execution failed: {sqlEx}");
                            //SweetAlert.Show(this, "Database Error", "A database error occurred. Please contact support.", "error");
                            return;
                        }

                        using (sdr)
                        {
                            if (!sdr.Read())
                            {
                                // No rows — invalid credentials

                                Session.Clear();
                                //SweetAlert.Show(this, "Login Failed", "Invalid username or password. Please try again.", "warning");
                                return;
                            }


                            // ── Read user fields safely ──────────────────────
                            int userId;
                            string userName, epfNo;

                            try
                            {
                                userId = Convert.ToInt32(sdr["UserID"]);
                                userName = sdr["UserName"].ToString();
                                epfNo = sdr["EPFNo"].ToString();

                                System.Diagnostics.Debug.WriteLine($"[Login] UserID={userId}, UserName={userName}, EPFNo={epfNo}");
                            }
                            catch (Exception fieldEx)
                            {
                                System.Diagnostics.Debug.WriteLine($"[Login][ERROR] Failed to read user fields: {fieldEx}");
                                //SweetAlert.Show(this, "Error", "An error occurred reading your account data. Please try again.", "error");
                                return;
                            }

                            // ── Write login log ──────────────────────────────
                            bool loggedIn;
                            try
                            {
                                loggedIn = CT.AddLoginLog(userId, 0, 1);

                            }
                            catch (Exception logEx)
                            {

                                //SweetAlert.Show(this, "Error", "Login audit failed. Please contact support.", "error");
                                return;
                            }

                            if (!loggedIn)
                            {

                                Session.Clear();
                                //SweetAlert.Show(this, "Sign In Failed", "Login could not be recorded. Please try again.", "error");
                                return;
                            }

                            // ── Set session ──────────────────────────────────
                            Session["username"] = userName;
                            Session["userid"] = userId.ToString();
                            Session["EPFNo"] = epfNo;
                            Session["ShowBanner"] = true;



                            // ── Issue Forms Auth cookie ──────────────────────
                            try
                            {
                                FormsAuthenticationTicket ticket = new FormsAuthenticationTicket(
                                    1,
                                    userName,
                                    DateTime.Now,
                                    DateTime.Now.AddMinutes(900),
                                    isPersistent: false,
                                    userData: "Application Specific data for this user.",
                                    cookiePath: FormsAuthentication.FormsCookiePath
                                );

                                string encTicket = FormsAuthentication.Encrypt(ticket);
                                Response.Cookies.Add(new HttpCookie(FormsAuthentication.FormsCookieName, encTicket));

                                DateTime ssoExpiry = DateTime.Now.AddHours(12);

                                Response.Cookies.Set(new HttpCookie("userinfo", userName)
                                {
                                    Expires = ssoExpiry,
                                    Path = "/",
                                    HttpOnly = true
                                });
                                Response.Cookies.Set(new HttpCookie("userid", userId.ToString())
                                {
                                    Expires = ssoExpiry,
                                    Path = "/",
                                    HttpOnly = true
                                });
                            }
                            catch (Exception authEx)
                            {
                                System.Diagnostics.Debug.WriteLine($"[Login][ERROR] Forms auth ticket creation failed: {authEx}");
                                //SweetAlert.Show(this, "Error", "Authentication setup failed. Please try again.", "error");
                                return;
                            }

                            // ── Redirect to Dashboard ────────────────────────

                            //Response.Redirect("~/Dashboard.aspx", false);  
                            //Context.ApplicationInstance.CompleteRequest();  

                            string returnUrl = Request.QueryString["ReturnUrl"];

                            if (!string.IsNullOrEmpty(returnUrl) && IsSafeLocalUrl(returnUrl))
                            {
                                Response.Redirect(returnUrl, false);
                            }
                            else
                            {
                                Response.Redirect("~/Home.aspx", false);
                            }
                            Context.ApplicationInstance.CompleteRequest();

                        }
                    }
                } // end using conn
            }
            catch (Exception ex)
            {
                // Catch-all for unexpected errors
                System.Diagnostics.Debug.WriteLine($"[Login][UNHANDLED ERROR] {ex}");
                //SweetAlert.Show(this, "Unexpected Error", "An unexpected error occurred. Please try again later.", "error");
            }
        }

        private bool IsSafeLocalUrl(string url)
        {
            if (string.IsNullOrWhiteSpace(url)) return false;

            // must be app-relative or root-relative, never protocol-relative or absolute
            if (url.StartsWith("~/")) return true;
            if (url.StartsWith("/") && !url.StartsWith("//") && !url.StartsWith("/\\")) return true;

            return false;
        }
    }
}
