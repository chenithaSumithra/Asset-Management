using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Asset_Management.Interfaces
{
    public interface IEmailService
    {
        Task sendEmailAsync(
            
            List<string> recipients,
            string subject,
            string body);
    }
}
