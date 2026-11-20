using Asset_Management.Interfaces;
using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;

namespace Asset_Management.Helpers
{
    public class ApprovalEmailService
    {
        private readonly IEmailService _emailService;

        public ApprovalEmailService(IEmailService emailService)
        {
            _emailService = emailService;
        }

        public async Task SendApprovalNotificationAsync(
            List<string> recipients,
            string transactionTag,
            int status,
            string note)
        {
            string action = status == 1 ? "Approved" : "Rejected";

            string subject = "Asset Transaction " + action + " - " + transactionTag;

            string body = string.Format(@"
                <html>
                <body style='font-family:Arial,sans-serif;'>
                    <h2>Asset Transaction {0}</h2>

                    <p>
                        Your asset transaction has been
                        <strong>{0}</strong>.
                    </p>

                    <p><strong>Transaction:</strong> {1}</p>

                    <p><strong>Status:</strong> {0}</p>

                    <p><strong>Note:</strong> {2}</p>

                    <p><strong>Date:</strong> {3}</p>

                    <hr/>

                    <p>Asset Management System</p>
                </body>
                </html>",
               action,
               HttpUtility.HtmlEncode(transactionTag),
               HttpUtility.HtmlEncode(note),
               DateTime.Now.ToString("yyyy-MM-dd HH:mm"));

            await _emailService.sendEmailAsync(recipients, subject, body).ConfigureAwait(false);
        }
    }
}