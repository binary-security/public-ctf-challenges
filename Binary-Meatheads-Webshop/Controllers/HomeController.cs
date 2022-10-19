using System;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using pdf_generator.Models;
using Microsoft.AspNetCore.Http;
using IronPdf;



namespace pdf_generator.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        private readonly int price = 100;


        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Order()
        {
            return View();
        }

        [HttpPost]
        [IgnoreAntiforgeryToken]
        public IActionResult OrderItem ([FromForm] int Quantity, [FromForm] String Name ){
            this._logger.LogInformation($"User ordered. Quantity: {Quantity} Product: {Name}");

            int total = Quantity * price;

            //
            //Here we could then generate a pdf so that it can be exploited, and read local files
            //It would be the same as above, real easy (but of course, it is slightly difficult since straight up files dont wo
            // work). We only need to set up some kind of thing to buy then. Could also make it more difficult here
            // set up some validation, set up some storage and login, so they dont get receipts right away, have
            // it be combined in some way, etc.
            //

            PdfPrintOptions printOptions = new PdfPrintOptions(){
                CssMediaType=PdfPrintOptions.PdfCssMediaType.Print,
                CustomCssUrl = @"/css/receipt.css",
                EnableJavaScript = true
            };

            // IronPdf.ChromePdfRenderOptions printOptions = new IronPdf.ChromePdfRenderOptions(){
            //     CustomCssUrl = @"/css/receipt.css",
            //     EnableJavaScript = true,
            // };

            string HTMLtemplate = System.IO.File.ReadAllText(@"wwwroot/html/receipt-template.html");

            var pngBinaryData = System.IO.File.ReadAllBytes(@"wwwroot/binsec_black.png");

            var imgDataURI = @"data:image/png;base64," + Convert.ToBase64String(pngBinaryData);

            string HTML = string.Format(HTMLtemplate, GlobalVariables.OrderCount++, Name, Quantity, total, total + 1200+60, imgDataURI);

            try{

                // Skip download of dependencies as they should already be installed.
                IronPdf.Installation.LinuxAndDockerDependenciesAutoConfig = true;

                IronPdf.HtmlToPdf Renderer = new IronPdf.HtmlToPdf(printOptions);
                var renderer = Renderer.RenderHtmlAsPdf(HTML);

                var contentType = "APPLICATION/octet-stream";
                return File(renderer.Stream, contentType, "test.pdf");

            } catch(Exception e){
                this._logger.LogError($"Exception occurred while rendering PDF {e.Message}");
                this._logger.LogError($"Stack trace: {e.StackTrace}");
                return StatusCode(StatusCodes.Status500InternalServerError, "Something went wrong");
            }

        }
        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
