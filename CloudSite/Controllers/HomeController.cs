﻿using CloudSite.Models;
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
            var model = new TextModel(text);
            return View(model);
        }

    }
}
