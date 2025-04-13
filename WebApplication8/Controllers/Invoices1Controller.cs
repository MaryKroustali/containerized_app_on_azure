
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using WebApplication8.Models;
using WebApplication8.ViewModel;
using System.Data.SqlClient;
using System.Collections.Generic;


namespace WebApplication8.Controllers
{
    public class Invoices1Controller : Controller
    {
        private Class1 db = new Class1();

        List<Invoice> invoices = new List<Invoice>();
        List<Employee> employees = new List<Employee>();

        // GET: Invoices1
        public ActionResult Index()
        {
            string since = "2012-01-01";
            string till = "2014-01-01";
            string customerF = "Roberto";
            string customerL = "Almeida";
            string employeeF = "Andrew";
            string employeeL = "Adams";

            using (var context = new ChinookEntities())
            {
                var data = context.Invoice.SqlQuery("[dbo].[query5] @StartDate, @StopDate, " +
                    "@customerFirst, @CustomerLast ," +
                    "@employeeFirst ,@EmployeeLast",
                    new SqlParameter("StartDate", since),
                    new SqlParameter("StopDate", till),
                    new SqlParameter("customerFirst", customerF),
                    new SqlParameter("CustomerLast", customerL),
                    new SqlParameter("employeeFirst", employeeF),
                    new SqlParameter("EmployeeLast", employeeL)).ToList();

                //var viewModel = new Class1() { Invoice1 = data };
                
                return View(data);
            }
        }
    }
}
