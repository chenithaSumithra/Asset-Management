using Asset_Management.Models;
using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Asset_Management.DAO
{
    public class AssetLookupResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public AssetDetails Asset { get; set; }
    }
}