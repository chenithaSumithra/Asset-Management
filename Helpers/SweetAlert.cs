using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;

namespace Asset_Management.Helpers
{
    public class SweetAlert
    {
        /*public static void Show(
             Page page,
             string title,
             string message,
             string icon,
             string buttonText = "OK")
        {
            string script = $@"
                Swal.fire({{
                    title: '{Escape(title)}',
                    text: '{Escape(message)}',
                    icon: '{icon}',
                    confirmButtonText: '{Escape(buttonText)}',
                    confirmButtonColor: '#0066ff',
                    heightAuto: false
                }});
            ";

            ScriptManager.RegisterStartupScript(
                page,
                page.GetType(),
                Guid.NewGuid().ToString(),
                script,
                true
            );
        }

        public static void ShowAndRedirect(Page page, string title,
            string message,
            string icon,
            string redirectUrl,
            int delay = 2000,
            string buttonText = "OK")


        {
            string resolvedUrl = page.ResolveUrl(redirectUrl);

            string script = $@"
        Swal.fire({{
            title: '{Escape(title)}',
            text: '{Escape(message)}',
            icon: '{icon}',
            showConfirmButton: false,
            timer: {delay},
            timerProgressBar: true,
            allowOutsideClick: false,
            heightAuto: false
        }});

        setTimeout(function () {{
            window.location.href = '{resolvedUrl}';
        }}, {delay});
    ";

            ScriptManager.RegisterStartupScript(
                page,
                page.GetType(),
                Guid.NewGuid().ToString(),
                script,
                true
            );
        }

        public static void ShowAndClose(Page page, string title, string message, string icon, int delay = 2000)
        {
            string script = $@"
    Swal.fire({{
        title: '{Escape(title)}',
        text: '{Escape(message)}',
        icon: '{icon}',
        showConfirmButton: false,
        timer: {delay},
        timerProgressBar: true,
        allowOutsideClick: false,
        heightAuto: false
    }});

    setTimeout(function () {{
        if (window.opener) {{
            window.close();                
        }} else if (window.history.length > 1) {{
            window.history.back();
        }} else {{
           window.close();
        }}
    }}, {delay});
";

            ScriptManager.RegisterStartupScript(
                page,
                page.GetType(),
                Guid.NewGuid().ToString(),
                script,
                true
            );
        }

        private static string Escape(string text)
        {
            return text
                .Replace("'", "\\'")
                .Replace("\r", "")
                .Replace("\n", "");
        }*/
    }
}