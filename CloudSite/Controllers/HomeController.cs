using CloudSite.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace CloudSite.Controllers
{
    public class HomeController : Controller
    {

        public ActionResult Index()
        {
            return View();
        }

        public ActionResult Text(string text)
        {
            if (String.IsNullOrEmpty(text))
            {
                return View("Index",(object) "Please enter text to display, showing an empty value is tricky");
            }
            else
            {
                var model = new TextModel(text);
                return View(model);
            }
        }

    }
}
