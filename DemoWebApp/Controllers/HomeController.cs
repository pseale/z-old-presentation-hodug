using System.Configuration;
using System.Web.Mvc;

namespace MvcApplication3.Controllers
{
    [HandleError]
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            ViewData["Message"] = "Welcome to ASP.NET MVC, " + ConfigurationManager.AppSettings["VIPName"];

            return View();
        }

        public ActionResult About()
        {
            return View();
        }
    }
}
