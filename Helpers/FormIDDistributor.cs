using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Asset_Management.Helpers
{
    public class FormIDDistributor
    {
        public const int SendApprovalEmail = 1;
        public const int SendRejectionEmail = 2;
        public const int ManageApprovals = 3;
        public const int ManageTransfer = 4;
        public const int DispatchDashboard = 5;
    }
}