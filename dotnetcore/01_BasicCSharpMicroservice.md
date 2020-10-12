# Basic Microservice with .Net Core 3.x

This exercise will cover the following:

- Building a simple web service with .Net core
- Deploying the service to PCF
- Using Steeltoe to bind to a redis cloud instance
- Doing a blue/green deployment with PCF

## Pre-Requisites

### .Net Core

1. Install the .Net core SDK from this URL: https://dotnet.microsoft.com/download
1. Verify the install by opening a terminal or command window and typing `dotnet --version`. You should see a version string to match the version you installed

### Install an IDE

1. Install either Visual Studio IDE or Visual Studio Code from this URL: https://visualstudio.microsoft.com/
1. If you choose Visual Studio Code, also install the C# extension

## Build a Simple Web Service

### Create the Basic Project

1. Create a basic web service project and open it in VS Code
   ```shell
   mkdir csharp-payment-calculator
   cd csharp-payment-calculator
   dotnet new webapi
   dotnet add package Swashbuckle.AspNetCore
   code .
   ```
1. Run the new web service with `dotnet run` (or just press F5 in Visual Studio/Code), then navigate to https://localhost:5001/WeatherForecast

1. Stop the service with `ctrl-c` (or press the stop button in Visual Studio/Code)

### Add a Payment Calculator

1. Create a new `Services` directory
1. Create a new class `PaymentService` in the `Services` directory, set its contents to the following:

   ```csharp
   using System;

   namespace PaymentCalculator.Services
   {
       public class PaymentService
       {
           public Decimal Calculate(double Amount, double Rate, int Years)
           {
               if (Rate == 0.0)
               {
                   return CalculateWithoutInterest(Amount, Years);
               }
               else
               {
                   return CalculateWithInterest(Amount, Rate, Years);
               }
           }

           private Decimal CalculateWithInterest(double Amount, double Rate, int Years)
           {
               double monthlyRate = Rate / 100.0 / 12.0;
               int numberOfPayments = Years * 12;
               double payment = (monthlyRate * Amount) / (1.0 - Math.Pow(1.0 + monthlyRate,
                   -numberOfPayments));
               return ToMoney(payment);
           }

           private Decimal CalculateWithoutInterest(double Amount, int Years)
           {
               int numberOfPayments = Years * 12;
               return ToMoney(Amount / numberOfPayments);
           }

           private Decimal ToMoney(double d)
           {
               Decimal bd = new Decimal(d);
               return Decimal.Round(bd, 2, MidpointRounding.AwayFromZero);
           }
       }
   }
   ```

### Add a Hit Counter

1. Create a new interface `IHitCounterService` in the `Services` directory, set its contents to the following:

   ```csharp
   namespace PaymentCalculator.Services
   {
       public interface IHitCounterService
       {
           long GetAndIncrement();
           void Reset();
       }
   }
   ```

1. Create a new Class `MemoryHitCounterService` in the `Services` directory, set its contents to the following:

   ```csharp
   namespace PaymentCalculator.Services
   {
       public class MemoryHitCounterService: IHitCounterService
       {
           private long HitCount = 0;
           public long GetAndIncrement()
           {
               return ++HitCount;
           }

           public void Reset()
           {
               HitCount = 0;
           }
       }
   }
   ```

### Add a Crash Service

Create a new Class `CrashService` in the `Services` directory, set its contents to the following:

```csharp
using System;
using System.Threading.Tasks;

namespace PaymentCalculator.Services
{
    public class CrashService
    {
        public void CrashIt()
        {
            // ends the app after a 2 second delay
            Task.Run(async delegate
            {
                await Task.Delay(2000);
                Environment.Exit(22);
            });
        }
    }
}
```

### Add a Basic Domain Object

1. Create a new `Models` directory
1. Create a new class `CalculatedPayment` in the `Models` directory, set its contents to the following:

   ```csharp
   namespace PaymentCalculator.Models
   {
       public class CalculatedPayment
       {
           public double Amount {get; set;}
           public double Rate {get; set;}
           public int Years {get; set;}
           public decimal Payment {get; set;}
           public string Instance {get; set;}
           public long Count {get; set;}
       }
   }
   ```

### Create a REST Controller for the Payment Service

Create a new class `PaymentController` in the `Controllers` directory, set its contents to the following:

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PaymentCalculator.Models;
using PaymentCalculator.Services;

namespace PaymentCalculator.Controllers
{
    [Route("/[controller]")]
    [ApiController]
    public class PaymentController
    {
        private PaymentService PaymentService;
        private IHitCounterService HitCounterService;

        private readonly ILogger _logger;

        public PaymentController(PaymentService paymentService,
                IHitCounterService hitCounterService,
                ILogger<PaymentController> logger)
        {
            PaymentService = paymentService;
            HitCounterService = hitCounterService;
            _logger = logger;
        }

        [HttpGet]
        public ActionResult<CalculatedPayment> calculatePayment(double Amount, double Rate, int Years)
        {
            var Payment = PaymentService.Calculate(Amount, Rate, Years);

            _logger.LogDebug("Calculated payment of {Payment} for input amount: {Amount}, rate: {Rate}, years: {Years}",
                Payment, Amount, Rate, Years);

            return new CalculatedPayment
            {
                Amount = Amount,
                Rate = Rate,
                Years = Years,
                Instance = "local",
                Count = HitCounterService.GetAndIncrement(),
                Payment = Payment
            };
        }
    }
}
```

### Create a REST Controller for the Hit Count Reset Service

Create a new class `ResetCountController` in the `Controllers` directory, set its contents to the following:

```csharp
using Microsoft.AspNetCore.Mvc;
using PaymentCalculator.Services;

namespace PaymentCalculator.Controllers
{
    [Route("/[controller]")]
    [ApiController]
    public class ResetCountController
    {
        private IHitCounterService HitCounterService;

        public ResetCountController(IHitCounterService hitCounterService)
        {
            HitCounterService = hitCounterService;
        }

        [HttpGet]
        public ActionResult<string> ResetCount()
        {
            HitCounterService.Reset();
            return "OK";
        }
    }
}
```

### Create a REST Controller for the Crash Service

Create a new class `CrashController` in the `Controllers` directory, set its contents to the following:

```csharp
using Microsoft.AspNetCore.Mvc;
using PaymentCalculator.Services;

namespace PaymentCalculator.Controllers
{
    [Route("/[controller]")]
    [ApiController]
    public class CrashController
    {
        private CrashService CrashService;
        public CrashController(CrashService crashService)
        {
            CrashService = crashService;
        }

        /// <summary>
        /// Warning! Executing this API will crash the application.
        /// </summary>
        [HttpGet]
        public ActionResult<string> CrashIt()
        {
            CrashService.CrashIt();
            return "OK";
        }
    }
}
```

### Setup Dependency Injection and the MVC Pipeline

1. Modify `Startup.cs` by adding the following lines at the end of the `ConfigureServices` method:

   ```csharp
   services.AddCors();
   services.AddOptions();
   services.AddSingleton<PaymentService>();
   services.AddSingleton<CrashService>();
   services.AddSingleton<IHitCounterService, MemoryHitCounterService>();
   ```

1. Modify `Startup.cs` by adding the following line in the `Configure` method prior to the existing line `app.UseHttpsRedirection();`:

   ```csharp
   app.UseCors(builder => builder.AllowAnyOrigin());
   ```

1. Start the application either with the debugger (F5), or by entering the command `dotnet run`

1. Try the web service with the URL https://localhost:5001/payment?amount=100000&rate=4.5&years=30

1. Verify that a payment of \$506.69 is returned

## Add Swagger

Swagger is a REST documentation and UI tool, that also includes code generation tools for clients. For us, it will act as a very simple and almost free UI for the web service we've just created. There are two implementations of swagger: Swashbuckle and NSwag. For this exercise, we will use Swashbuckle.

1. Modify `Startup.cs`, add the following to the end of the `ConfigureServices` method:

   ```csharp
   services.AddSwaggerGen(c =>
   {
       c.SwaggerDoc("v1", new OpenApiInfo { Title = "My API", Version = "v1" });
   });
   ```

1. Modify `Startup.cs`, add the following to the end of the `Configure` method:

   ```csharp
   app.UseSwagger();
   app.UseSwaggerUI(c =>
   {
       c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API V1");
       c.RoutePrefix = string.Empty;
   });
   ```

1. Start the application. The swagger UI should now be available at the application root (https://localhost:5001)

1. Notice that Swagger has documented all web services - the services we wrote as well as the default service generated by dotnet. If you want, you can delete the generated web service by deleting `WeatherForecastController.cs` and `WeatherForecast.cs`
