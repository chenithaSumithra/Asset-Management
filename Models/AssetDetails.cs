using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Asset_Management.Models
{
    public class AssetDetails
    {
        public string BarcodeId { get; set; }
        public string AssetName { get; set; }
        public string Serial { get; set; }
        public string MachineNo { get; set; }
        public string Model { get; set; }
        public string Model_No { get; set; }
        public string Status { get; set; }
        
        public string StatusName { get; set; }
        public string Condition { get; set; }
        public string Company { get; set; }
        public string CurrentLocation { get; set; }
    }
}