using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Web;

namespace Asset_Management.Helpers
{
    public class Logger 
    {
       public static void Lo(string message)
        {
         
           System.Diagnostics.Debug.WriteLine($"{DateTime.Now}: {message}");
        }
    }
}