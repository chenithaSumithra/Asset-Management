using Asset_Management.Interfaces;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Security.Cryptography.Pkcs;
using System.Threading.Tasks;
using System.Web;

namespace Asset_Management.Helpers
{
    public class SMTPEmailService : IEmailService
    {
        public async Task sendEmailAsync(
            List<string> recipients,
            string subject,
            string body)
        {
            if (recipients == null || recipients.Count == 0)
                throw new ArgumentException(
                    "At least one recipient is required");

            List<string> validRecipients = recipients
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if(validRecipients.Count == 0)
                throw new ArgumentException (
                    "No valid recipients provided");

            string host = ConfigurationManager.AppSettings["SMTPHost"];
            int port = int.Parse(ConfigurationManager.AppSettings["SmtpPort"]);
            string username = ConfigurationManager.AppSettings["SmtpUser"];
            string password = Environment.GetEnvironmentVariable("ASSET_SMPT_PASSWORD");

            string from = ConfigurationManager.AppSettings["SmtpFrom"];

            if (string.IsNullOrWhiteSpace(password))
                throw new InvalidOperationException(
                    "SMTP password is not configured");

            using (var message = new MailMessage())
            {
                message.From = new MailAddress(from);
             
                foreach (string email in validRecipients)
                {
                    message.To.Add(new MailAddress(email));
                }

                message.Subject = subject;
                message.Body = body;
                message.IsBodyHtml = true;

                using (var client = new SmtpClient(host, port))
                {
                    client.EnableSsl = true;
                    client.UseDefaultCredentials = false;

                    client.Credentials = new NetworkCredential(username, password);

                    await client.SendMailAsync(message).ConfigureAwait(false);
                }
            }
        }
    }
}