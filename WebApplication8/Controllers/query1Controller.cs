using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.Entity;
using System.Net;
using WebApplication8.Models;
using System.Threading.Tasks;

namespace WebApplication8.Controllers
{
    public class query1Controller : Controller
    {
        private ChinookEntities db = new ChinookEntities();
        // GET: query1
        public ActionResult TestAction()
        {
            return View();
        }
    }
}