using System.Configuration;
using System.Web.Mvc;

namespace MvcApplication3.Controllers
{
    [HandleError]
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            ViewData["Message"] = "Welcome to ASP.NET MVC, " + ConfigurationManager.AppSettings["VIPName"];  //demo-quality MVC code
            ViewData["PuttingEverythingInTheViewDataHashIsAnASPNETMVCBestPractice"] = this.GetType().Assembly.GetName().Version;  //demo-quality MVC code

            return View();
        }

        public ActionResult About()
        {
            return View();
        }
    }
}
