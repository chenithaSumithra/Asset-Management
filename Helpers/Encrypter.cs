using Microsoft.AspNet.SignalR;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Asset_Management.Helpers
{
    public class Encrypter
    {
        public const string CON_ENCRYPT_KEY = "APMaS";


        public static string Encrypt(string modINDATA, string modPASSWORD)
        {
            System.Diagnostics.Debug.WriteLine("Recieved modINDATA: " + modINDATA + " " + "modPASSWORD: " + modPASSWORD);

            long pwSum = 0;
            long x = 0;
            string strEncrypt = "";

            if ((modINDATA.Length) != 0)
                if ((modPASSWORD.Length) != 0)
                {
                    for (int i = 0; i < (modPASSWORD.Length); i++)
                    {

                        pwSum = pwSum + (long)System.Text.Encoding.ASCII.GetBytes(modPASSWORD.Substring(i, 1))[0];

                    }

                    for (int i = 0; i < (modINDATA.Length); i++)
                    {

                        x = (long)System.Text.Encoding.ASCII.GetBytes(modINDATA.Substring(i, 1))[0] + pwSum;

                        while (x > 254)
                        {
                            x = (x - 254);
                        }

                        strEncrypt = strEncrypt + Convert.ToChar(x);
                    }
                }
            return (strEncrypt);
        }



        public static string Decrypt(string modINDATA, string modPASSWORD)
        {
            long pwSum = 0;
            long x = 0;
            string strEncrypt = "";

            if ((modINDATA.Length) != 0)
                if ((modPASSWORD.Length) != 0)
                {
                    for (int i = 0; i < (modPASSWORD.Length); i++)
                    {

                        pwSum = pwSum + (long)System.Text.Encoding.ASCII.GetBytes(modPASSWORD.Substring(i, 1))[0];

                    }

                    for (int i = 0; i < (modINDATA.Length); i++)
                    {
                        x = 0;
                        x = (long)modINDATA[i];
                        x = x - pwSum;
                        while (x < 1)
                        {
                            x = (x + 254);
                        }

                        strEncrypt = strEncrypt + Convert.ToChar(x);
                    }
                }
            //strEncrypt = "iliyana1997vera";
            System.Diagnostics.Debug.WriteLine("Returning strEncrypt: " + strEncrypt);
            return (strEncrypt);
        }
    }
}