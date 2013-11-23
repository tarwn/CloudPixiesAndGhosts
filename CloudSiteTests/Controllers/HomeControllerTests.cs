using CloudSite.Controllers;
using CloudSite.Models;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace CloudSiteTests.Controllers
{
    [TestFixture]
    public class HomeControllerTests
    {

        [Test]
        public void Index_ReturnsViewResult()
        {
            var controller = new HomeController();

            var result = controller.Index();

            Assert.IsInstanceOf<ViewResult>(result);
        }

        [Test]
        public void Text_ValidInput_ReturnsViewModel()
        {
            var controller = new HomeController();
            string validInput = "Some text";

            var result = controller.Text(validInput);

            Assert.IsInstanceOf<ViewResult>(result);
        }

        [Test]
        public void Text_ValidInput_ModelContainsInputText()
        {
            var controller = new HomeController();
            string validInput = "Some text";

            var result = controller.Text(validInput);

            Assert.IsInstanceOf<ViewResult>(result);
            var model = ((ViewResult)result).Model;
            Assert.IsInstanceOf<TextModel>(model);
            Assert.AreEqual(validInput, ((TextModel)model).Text);
        }

        [Test]
        public void Text_EmptyInput_DisplaysFormWithError()
        {
            var controller = new HomeController();
            string invalidInput = "";

            var result = controller.Text(invalidInput);

            Assert.IsInstanceOf<ViewResult>(result);
            var viewResult = (ViewResult) result;
            Assert.AreEqual("Index", viewResult.ViewName);
            Assert.IsInstanceOf<String>(viewResult.Model);
        }
    }
}
