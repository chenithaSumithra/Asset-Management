using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Asset_Management.DAO
{
    public class CheckoutRequest
    {
        public string checkoutType { get; set; }
        public string destinationType { get; set; }
        public string destinationId { get; set; }

        public string managerId { get; set; }
        public string supplierId { get; set; }
        public string companyId { get; set; }

        public string returnType { get; set; }
        public string checkoutDate { get; set; }
        public string expectedCheckinDate { get; set; }

        public string note { get; set; }
        public List<string> barcodeIds { get; set; }
    }
}