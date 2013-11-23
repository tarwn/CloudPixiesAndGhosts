using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CloudSite.Models
{
    public class TextModel
    {
        public TextModel(string text)
        {
            Text = text;
        }

        public string Text { get; set; }
    }
}