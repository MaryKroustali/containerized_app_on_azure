using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Data.Entity.Core.Objects;
using WebApplication8.Models;
using System.Collections.Generic;

namespace WebApplication8.ViewModel
{
    public class Class1 : DbContext
    {
        public Employee employee { get; set; }
        public Customer customer { get; set; }
        public Invoice invoice { get; set; }

        public string FirstNameC { get; set; }
        public string LastNameC { get; set; }
        public string LastNameE { get; set; }
        public string FirstNameE { get; set; }
        public int InvoiceId { get; set; }

        public System.Data.Entity.DbSet<WebApplication8.Models.Invoice> Invoices { get; set; }

        public System.Data.Entity.DbSet<WebApplication8.Models.Customer> Customers { get; set; }
    }
}