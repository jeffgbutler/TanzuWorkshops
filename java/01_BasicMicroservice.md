# Basic Microservice with Java and Spring Boot

## Pre-Requisites

### Install an IDE

Install and configure a Java IDE you are comfortable with. Good options include:

- Eclipse: https://www.eclipse.org/
- IntelliJ: https://www.jetbrains.com/idea/
- Visual Studio Code: https://visualstudio.microsoft.com/

If you install Visual Studio Code, then add the following extensions:

- (Microsoft) Java Extension Pack
- (Pivotal) Spring Boot Extension Pack

## Create the Basic Application

1. Navigate to [https://start.spring.io](https://start.spring.io)
1. Create a Maven project with Java and the latest version of Spring Boot (2.3.4 at the time of writing)
1. Specify group: `tanzu.workshop`
1. Specify artifact: `payment-calculator`
1. Specify packaging: Jar
1. Specify Java Version to match what you have installed
1. For dependencies, add the following:
   - Spring Web
   - Spring Boot Actuator
1. Generate the project (causes a download)
1. Unzip the downloaded file somewhere convenient
1. Add the new project to your IDE workspace
   - Eclipse: File->Import->Existing Maven Project
   - IntelliJ: File->New->Module From Existing Sources...
   - VS Code: File->Add Folder to Workspace (or just open the folder by navigating to it and entering the command `code .`)

## Configure The Info Actuator

1. Rename `application.properties` in `src/main/resources` to `application.yml`
1. Open `application.yml` in `src/main/resources`
1. Add this value

   ```yml
   info:
     app:
       name: Payment Calculator

   management:
     endpoint:
       health:
         show-details: always
   ```

## Configure Swagger

1. Open `pom.xml`, add the following dependencies:

   ```xml
   <dependency>
     <groupId>io.springfox</groupId>
     <artifactId>springfox-boot-starter</artifactId>
     <version>3.0.0</version>
   </dependency>
   ```

1. Create a class `SwaggerConfiguration` in the `tanzu.workshop.paymentcalculator` package. Add the following:

   ```java
   package tanzu.workshop.paymentcalculator;

   import org.springframework.context.annotation.Bean;
   import org.springframework.context.annotation.Configuration;
   import org.springframework.stereotype.Controller;
   import org.springframework.web.bind.annotation.RequestMapping;
   import org.springframework.web.bind.annotation.RestController;
   import org.springframework.web.servlet.view.RedirectView;
   import springfox.documentation.builders.RequestHandlerSelectors;
   import springfox.documentation.spi.DocumentationType;
   import springfox.documentation.spring.web.plugins.Docket;
   import springfox.documentation.swagger2.annotations.EnableSwagger2;

   @Configuration
   @EnableSwagger2
   @Controller
   public class SwaggerConfiguration {

       @RequestMapping("/")
       public RedirectView redirectToSwagger() {
           return new RedirectView("swagger-ui/");
       }

       @Bean
       public Docket api() {
           return new Docket(DocumentationType.SWAGGER_2)
                   .select()
                   .apis(RequestHandlerSelectors.withClassAnnotation(RestController.class))
                   .build();
       }
   }
   ```

   This configuration does three important things:

   1. It enables Swagger
   1. It redirects the root URL to the Swagger UI. I find this convenient, but YMMV
   1. It tells Springfox that we only want to use Swagger for REST controllers. Without this there will be Swagger documentation for the redirect controller, as well as the basic Spring error controller and we usually don't want this.

## Create a Payment Service

1. Create a package `tanzu.workshop.paymentcalculator.service`
1. Create a class in the new package called `PaymentService`
1. Set the content of `PaymentService` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.service;

   import java.math.BigDecimal;
   import java.math.RoundingMode;

   import org.springframework.stereotype.Service;

   @Service
   public class PaymentService {

       public BigDecimal calculate(double amount, double rate, int years) {
           if (rate == 0.0) {
               return calculateWithoutInterest(amount, years);
           } else {
               return calculateWithInterest(amount, rate, years);
           }
       }

       private BigDecimal calculateWithInterest(double amount, double rate, int years) {
           double monthlyRate = rate / 100.0 / 12.0;
           int numberOfPayments = years * 12;
           double payment = (monthlyRate * amount) / (1.0 - Math.pow(1.0 + monthlyRate, -numberOfPayments));
           return toMoney(payment);
       }

       private BigDecimal calculateWithoutInterest(double amount, int years) {
           int numberOfPayments = years * 12;
           return toMoney(amount / numberOfPayments);
       }

       private BigDecimal toMoney(double d) {
           BigDecimal bd = new BigDecimal(d);
           return bd.setScale(2, RoundingMode.HALF_UP);
       }
   }
   ```

## Create a Hit Counter Service

1. Create an interface in the `tanzu.workshop.paymentcalculator.service` package called `HitCounterService`
1. Set the content of `HitCounterService` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.service;

   public interface HitCounterService {
       long incrementCounter();
       void resetCount();
   }
   ```

1. Create a class in the `tanzu.workshop.paymentcalculator.service` package called `MemoryHitCounterService`
1. Set the content of `MemoryHitCounterService` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.service;

   import org.springframework.stereotype.Service;

   @Service
   public class MemoryHitCounterService implements HitCounterService {

       private long hitCount = 0;

       @Override
       public long incrementCounter() {
           return ++hitCount;
       }

       @Override
       public void resetCount() {
           hitCount = 0;
       }
   }
   ```

## Create a Crash Service

1. Create a class in the `tanzu.workshop.paymentcalculator.service` package called `CrashService`
1. Set the content of `CrashService` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.service;

   import java.util.concurrent.Executors;
   import java.util.concurrent.ScheduledExecutorService;
   import java.util.concurrent.TimeUnit;

   import org.springframework.stereotype.Service;

   @Service
   public class CrashService {
       private ScheduledExecutorService executer = Executors.newScheduledThreadPool(1);

       // calls System.exit after a 2 second delay
       public void crashIt() {
           executer.schedule(() -> System.exit(22), 2000, TimeUnit.MILLISECONDS);
       }
   }
   ```

## Create a Return Model

1. Create a package `tanzu.workshop.paymentcalculator.model`
1. Create a class in the new package called `CalculatedPayment`
1. Set the content of `CalculatedPayment` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.model;

   import java.math.BigDecimal;

   public class CalculatedPayment {
       private double amount;
       private double rate;
       private int years;
       private BigDecimal payment;
       private String instance;
       private Long count;

       // TODO: add getters and setters for all fields...
   }
   ```

## Create a REST Controller for the Payment Service

1. Create a package `tanzu.workshop.paymentcalculator.http`
1. Create a class in the new package called `PaymentController`
1. Set the content of `PaymentController` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.http;

   import java.math.BigDecimal;

   import org.slf4j.Logger;
   import org.slf4j.LoggerFactory;
   import org.springframework.beans.factory.annotation.Autowired;
   import org.springframework.beans.factory.annotation.Value;
   import org.springframework.web.bind.annotation.CrossOrigin;
   import org.springframework.web.bind.annotation.GetMapping;
   import org.springframework.web.bind.annotation.RequestMapping;
   import org.springframework.web.bind.annotation.RequestParam;
   import org.springframework.web.bind.annotation.RestController;

   import tanzu.workshop.paymentcalculator.model.CalculatedPayment;
   import tanzu.workshop.paymentcalculator.service.HitCounterService;
   import tanzu.workshop.paymentcalculator.service.PaymentService;

   @CrossOrigin(origins = "*")
   @RestController
   @RequestMapping("/payment")
   public class PaymentController {

       @Value("${cloud.application.instance_index:local}")
       private String instance;

       @Autowired
       private HitCounterService hitCounterService;

       @Autowired
       private PaymentService paymentService;

       private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);

       @GetMapping()
       public CalculatedPayment calculatePayment(@RequestParam("amount") double amount, @RequestParam("rate") double rate,
               @RequestParam("years") int years) {

           BigDecimal payment = paymentService.calculate(amount, rate, years);

           logger.debug("Calculated payment of {} for input amount: {}, rate: {}, years: {}",
               payment, amount, rate, years);

           CalculatedPayment calculatedPayment = new CalculatedPayment();
           calculatedPayment.setAmount(amount);
           calculatedPayment.setRate(rate);
           calculatedPayment.setYears(years);
           calculatedPayment.setPayment(payment);
           calculatedPayment.setInstance(instance);
           calculatedPayment.setCount(hitCounterService.incrementCounter());

           return calculatedPayment;
       }
   }
   ```

## Create a REST Controller to Reset the Hit Count

This is needed for the unit tests - it will reset the hit counter to a known state for each test.

1. Create a class `ResetHitCounterController` in package `tanzu.workshop.paymentcalculator.http`
1. Set the content of `ResetHitCounterController` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.http;

   import org.springframework.beans.factory.annotation.Autowired;
   import org.springframework.web.bind.annotation.CrossOrigin;
   import org.springframework.web.bind.annotation.GetMapping;
   import org.springframework.web.bind.annotation.RequestMapping;
   import org.springframework.web.bind.annotation.RestController;

   import tanzu.workshop.paymentcalculator.service.HitCounterService;

   @CrossOrigin(origins = "*")
   @RestController
   @RequestMapping("/resetCount")
   public class ResetHitCounterController {

       @Autowired
       private HitCounterService hitCounterService;

       @GetMapping
       public void reset() {
           hitCounterService.resetCount();
       }
   }
   ```

## Create a REST Controller to Crash the Application

This is needed to demonstrate Kubernetes' self-healing capabilities.

1. Create a class `CrashController` in package `tanzu.workshop.paymentcalculator.http`
1. Set the content of `CrashController` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.http;

   import org.springframework.beans.factory.annotation.Autowired;
   import org.springframework.web.bind.annotation.CrossOrigin;
   import org.springframework.web.bind.annotation.GetMapping;
   import org.springframework.web.bind.annotation.RequestMapping;
   import org.springframework.web.bind.annotation.RestController;

   import io.swagger.annotations.ApiOperation;
   import tanzu.workshop.paymentcalculator.service.CrashService;

   @CrossOrigin(origins = "*")
   @RestController
   @RequestMapping("/crash")
   public class CrashController {

       @Autowired
       private CrashService crashService;

       @ApiOperation("Warning! The application will crash 2 seconds after this method is called")
       @GetMapping()
       public String crashIt() {
           crashService.crashIt();
           return "OK";
       }
   }
   ```

## Unit Tests

1. Make a new package `tanzu.workshop.paymentcalculator.http` in the `src/test/java` tree
1. Create a class in the new package called `PaymentControllerTest`
1. Set the content of `PaymentControllerTest` to the following:

   ```java
   package tanzu.workshop.paymentcalculator.http;

   import static org.hamcrest.Matchers.*;
   import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
   import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
   import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
   import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
   import static org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup;

   import org.junit.jupiter.api.BeforeEach;
   import org.junit.jupiter.api.Test;
   import org.junit.jupiter.api.extension.ExtendWith;
   import org.springframework.beans.factory.annotation.Autowired;
   import org.springframework.boot.test.context.SpringBootTest;
   import org.springframework.http.HttpStatus;
   import org.springframework.http.MediaType;
   import org.springframework.test.context.junit.jupiter.SpringExtension;
   import org.springframework.test.web.servlet.MockMvc;
   import org.springframework.web.context.WebApplicationContext;

   @ExtendWith(SpringExtension.class)
   @SpringBootTest
   public class PaymentControllerTest {
       private MockMvc mockMvc;

       @Autowired
       private WebApplicationContext webApplicationContext;

       @BeforeEach
       public void setup() {
           this.mockMvc = webAppContextSetup(webApplicationContext).build();
       }

       @Test
       public void testWithInterest() throws Exception {
           mockMvc.perform(get("/resetCount"))
           .andExpect(status().is(HttpStatus.OK.value()));

           mockMvc.perform(get("/payment?amount=100000&rate=3.5&years=30"))
           .andExpect(status().is(HttpStatus.OK.value()))
           .andExpect(content().contentType(MediaType.APPLICATION_JSON))
           .andExpect(jsonPath("$.payment", is(449.04)))
           .andExpect(jsonPath("$.count", is(1)));
       }

       @Test
       public void testZeroInterest() throws Exception {
           mockMvc.perform(get("/resetCount"))
           .andExpect(status().is(HttpStatus.OK.value()));

           mockMvc.perform(get("/payment?amount=100000&rate=0&years=30"))
           .andExpect(status().is(HttpStatus.OK.value()))
           .andExpect(content().contentType(MediaType.APPLICATION_JSON))
           .andExpect(jsonPath("$.payment", is(277.78)))
           .andExpect(jsonPath("$.count", is(1)));
       }

       @Test
       public void testThatHitCounterIncrements() throws Exception {
           mockMvc.perform(get("/resetCount"))
           .andExpect(status().is(HttpStatus.OK.value()));

           mockMvc.perform(get("/payment?amount=100000&rate=3.5&years=30"))
           .andExpect(status().is(HttpStatus.OK.value()))
           .andExpect(content().contentType(MediaType.APPLICATION_JSON))
           .andExpect(jsonPath("$.payment", is(449.04)))
           .andExpect(jsonPath("$.count", is(1)));

           mockMvc.perform(get("/payment?amount=100000&rate=0&years=30"))
           .andExpect(status().is(HttpStatus.OK.value()))
           .andExpect(content().contentType(MediaType.APPLICATION_JSON))
           .andExpect(jsonPath("$.payment", is(277.78)))
           .andExpect(jsonPath("$.count", is(2)));
       }
   }
   ```

## Testing

1. Run the unit tests:

   - (Windows Command Prompt) `mvnw clean test`
   - (Windows Powershell) `.\mvnw clean test`
   - (Mac/Linux) `./mvnw clean test`
   - Or your IDE's method of running tests

1. Start the application:

   - (Windows Command Prompt) `mvnw spring-boot:run`
   - (Windows Powershell) `.\mvnw spring-boot:run`
   - (Mac/Linux) `./mvnw spring-boot:run`
   - Or your IDE's method of running the main application class

1. Test Swagger [http://localhost:8080](http://localhost:8080)
1. Test the acuator health endpoint [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health)
1. Test the acuator info endpoint [http://localhost:8080/actuator/info](http://localhost:8080/actuator/info)
