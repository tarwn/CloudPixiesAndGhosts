using CassiniDev;
using CloudSite;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace CloudPixiesTests
{
    [TestFixture]
    public class InitialTests
    {
        private CassiniDevServer _server;

        [TestFixtureSetUp]
        public void SetupWebSite()
        {
            var siteLocation = Path.GetDirectoryName(Assembly.GetAssembly(typeof(MvcApplication)).Location) + "\\..";
            _server = new CassiniDevServer();
            _server.StartServer(siteLocation);
        }

        [TestFixtureTearDown]
        public void TeardownWebSite()
        {
            _server.StopServer();
        }

        [Test]
        public void RootPage_LoadsSuccesfully()
        {
            string url = _server.NormalizeUrl("/");
            var client = new WebClient();

            var result = client.DownloadString(url);

            Assert.IsTrue(result.Contains("<h2>Index</h2>"));
        }

    }
}
