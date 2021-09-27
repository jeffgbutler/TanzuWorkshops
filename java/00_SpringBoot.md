# Basics of Spring Boot Exercise

This exercise will show the basics of Spring Boot through a few different types of microservice endpoints.

## Install Pre-Requisites

1. Install a JDK. We recommend installing JDK version 11. Good options include:

   - Amazon Corretto: https://aws.amazon.com/corretto/
   - BellSoft Liberica: https://bell-sw.com/pages/downloads/
   - Eclipse Temurin: https://adoptium.net/index.html

   If this is the first and only JDK you install, take the install defaults and allow the JDK to be placed in your PATH
   and allow setting of the `JAVA_HOME` environment
   variable - this will make IDE integration automatic. If you have multiple versions of JDKs installed,
   we assume you already have a good strategy for managing the currently active version.

   The SDKMAN! tool (https://sdkman.io/) can automaticallty install and manage multiple JDK versions on
   UNIX-like systems (MacOS, Linux, WSL, etc.) Highly recommended.

1. Install and configure a Java IDE you are comfortable with. Good options include:

   - Eclipse: https://www.eclipse.org/
   - IntelliJ: https://www.jetbrains.com/idea/
   - Visual Studio Code: https://visualstudio.microsoft.com/

1. If you install Visual Studio Code, then add the following extensions:

   - (Microsoft) Java Extension Pack
   - (Pivotal) Spring Boot Extension Pack

## Create the Basic Application

1. Navigate to [https://start.spring.io](https://start.spring.io)
1. Specify options:
   - Project Type: Maven
   - Language: Java
   - Spring Boot: the latest version of Spring Boot (2.5.5 at the time of writing)
   - Group: `microservice.workshop`
   - Artifact: `boot-demo`
   - Name, Description, Package Name: accepts the defaults
   - Packaging: Jar
   Java Version: 11
1. For dependencies, add the following:
    - Spring Web
    - Spring Boot Actuator
    - Spring Data JPA
    - H2 Database
1. Generate the project (causes a download)
1. Unzip the downloaded file somewhere convenient
1. Add the new project to your IDE workspace
    - Eclipse: File->Import->Existing Maven Project
    - IntelliJ: File->New->Module From Existing Sources...
    - VS Code: File->Add Folder to Workspace (or just open the folder by navigating to it and entering the command `code .`)

## Configure The Actuators

1. Open `application.properties` in `src/main/resources`
1. Add these values:

    ```properties
    info.app.name=Spring Boot Demo
    management.endpoint.health.show-details=ALWAYS
    management.endpoints.web.exposure.include=*
    ```

    Note: this setting for `management.endpoints.web.exposure.include=*` will expose EVERY actuator endpoint. You probably don't want to do this
    in a production setting! For production, the default setting is `management.endpoints.web.exposure.include=health`

## Configure Swagger

1. Open `pom.xml`, add the following dependencies:

    ```xml
    <dependency>
      <groupId>io.springfox</groupId>
      <artifactId>springfox-boot-starter</artifactId>
      <version>3.0.0</version>
    </dependency>
    ```

1. Create a class `SwaggerConfiguration` in the `micoservice.workshop.bootdemo` package. Add the following:

    ```java
    package microservice.workshop.bootdemo;

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
    1. It tells Springfox that we only want to use Swagger for REST controllers. Without this there will be Swagger
       documentation for other controllers built into Spring such as the redirect controller, and the basic Spring
       error controller - we usually don't want this.

## Test the Application

1. Start the application one of the following ways:
    - (Windows Command Prompt) `mvnw spring-boot:run`
    - (Windows Powershell) `.\mvnw spring-boot:run`
    - (Mac/Linux) `./mvnw spring-boot:run`
    - Use your IDE's Spring Boot support to start the application
    - Use your IDE's method of running the main application class (`BootDemoApplication.java`)

1. Test Swagger [http://localhost:8080](http://localhost:8080)
1. Test the actuator health endpoint [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health)
1. Test the actuator info endpoint [http://localhost:8080/actuator/info](http://localhost:8080/actuator/info)

## Create and Test a "Hello World" Endpoint

In this exercise, we will create a very simple REST endpoint to show the basics of wiring up a REST controller in Spring Boot.

1. Create a package `microservice.workshop.bootdemo.controller`
1. Create a class in the new package called `HelloController`
1. Set the contents of `HelloController` to the following:

    ```java
    package microservice.workshop.bootdemo.controller;

    import org.springframework.web.bind.annotation.GetMapping;
    import org.springframework.web.bind.annotation.RestController;

    @RestController
    public class HelloController {
        @GetMapping("/hello")
        public String hello() {
            return "Hello World";
        }
    }
    ```

    The `@RestController` annotation helps Spring Boot find the controller. It also sets up a lot of basic plumbing like
    JSON marshalling, error handling, etc.

    The `@GetMapping` annotation defines the URL for thisendpoint - and this one will only respond to an HTTP GET request.

1. Start the application
1. Test Swagger [http://localhost:8080](http://localhost:8080) - your new endpoint should be in Swagger
1. You can also test the endpoint by navigating directly to it: [http://localhost:8080/hello](http://localhost:8080/hello)

## Create and Test a Simple Calculator Endpoint

In this exercise we will create a simple calculator REST endpoint. This exercise will show how Spring dependency injection (DI) works.

1. Create a package `microservice.workshop.bootdemo.service`
1. Create a class in the new package called `MathService`
1. Set the contents of `MathService` to the following:

    ```java
    package microservice.workshop.bootdemo.service;

    import org.springframework.stereotype.Service;

    @Service
    public class MathService {
        public int add(int a, int b) {
            return a + b;
        }
    }
    ```

    This is a very simple service that adds two integers and returns the answer. It is good practice in any OO language
    to use the "single responsibility principle" which means that a class is responsible for one, and only one, thing. In
    this case, the class has no idea that we are about to use it in a REST service.

    The `@Service` annotation is a Spring "stereotype". Spring Boot will find this class at runtime and add it to the
    DI container because of the annotation.

1. Create a class in the `microservice.workshop.bootdemo.controller` package called `MathController`
1. Set the contents of `MathController` to the following:

    ```java
    package microservice.workshop.bootdemo.controller;

    import org.springframework.web.bind.annotation.GetMapping;
    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RequestParam;
    import org.springframework.web.bind.annotation.RestController;
    import microservice.workshop.bootdemo.service.MathService;

    @RestController
    @RequestMapping("/math")
    public class MathController {
        private MathService mathService;

        public MathController(MathService mathService) {
            this.mathService = mathService;
        }

        @GetMapping("/add")
        public int add(@RequestParam("a") int a, @RequestParam("b") int b) {
            return mathService.add(a, b);
        }
    }
    ```

    This REST controller makes use of the MathService through constructor based dependency injection.
    The `@RequestMapping` annotation defines a base URL for all the endpoints defined in this class. The `@GetMapping`
    annotation adds a path to the base URL and declares that this endpoint will be accessed by an HTTP GET request.
    The `@RequestParam` annotations name the query string parameters that will be mapped to method parameters. Note
    that Spring Boot will automatically convert Strings to Integers.
    The full URL for this request is `/math/add?a=X&b=y`

1. Start the application
1. Test Swagger [http://localhost:8080](http://localhost:8080) - your new endpoint should be in Swagger
1. You can also test the endpoint by navigating directly to it: [http://localhost:8080/math/add?a=5&b=6](http://localhost:8080/math/add?a=5&b=6)

## Create a CRUD Endpoint 
### Create a Person Repository

1. Create a package `microservice.workshop.bootdemo.model`
1. Create a class in the new package called `Person`
1. Set the content of `Person` to the following:

    ```java
    package microservice.workshop.bootdemo.model;

    import javax.persistence.Entity;
    import javax.persistence.GeneratedValue;
    import javax.persistence.GenerationType;
    import javax.persistence.Id;

    @Entity
    public class Person {
        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Integer id;
        private String firstName;
        private String lastName;

        // TODO: add getters and setters for all fields...
    }
    ```

1. Create a package `microservice.workshop.bootdemo.data`
1. Create an interface in the new package called `PersonRepository`
1. Set the content of `PersonRepository` to the following:

    ```java
    package microservice.workshop.bootdemo.data;

    import java.util.List;
    import java.util.Optional;

    import org.springframework.data.jpa.repository.JpaRepository;

    import microservice.workshop.bootdemo.model.Person;

    public interface PersonRepository extends JpaRepository<Person, Integer> {
        List<Person> findByLastName(String lastName);
        Optional<Person> findByFirstNameAndLastName(String firstName, String lastName);
    }
    ```

    `JpaRepository` is an interface that contains basic CRUD operations. In this case we have added
    two custom query methods. JPA will generate the appropriate SQL based on the method names.

1. Create a file called `import.sql` in `src/main/resources`. Set the contents to the following:

    ```sql
    insert into person(first_name, last_name) values('Fred', 'Flintstone');
    insert into person(first_name, last_name) values('Wilma', 'Flintstone');
    insert into person(first_name, last_name) values('Barney', 'Rubble');
    insert into person(first_name, last_name) values('Betty', 'Rubble');
    ```

    On application startup, Spring Boot will create an in-memory database using H2, create a schema based on the `@Entity` beans,
    and then run this script. This all comes for free when H2 is the only database driver on the class path. This is great for testing.
    In production, Spring Boot will not run this script by default as there will be a connection to a persistent database like MySQL or
    PostgreSQL.

### Create a REST Controller for CRUD Operations

1. Create a class in the `microservice.workshop.bootdemo.controller` package called `PersonController`
1. Set the content of `PersonController` to the following:

    ```java
    package microservice.workshop.bootdemo.controller;

    import java.util.List;
    import java.util.Optional;

    import org.springframework.beans.factory.annotation.Autowired;
    import org.springframework.http.HttpHeaders;
    import org.springframework.http.HttpStatus;
    import org.springframework.http.ResponseEntity;
    import org.springframework.web.bind.annotation.DeleteMapping;
    import org.springframework.web.bind.annotation.GetMapping;
    import org.springframework.web.bind.annotation.PathVariable;
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.PutMapping;
    import org.springframework.web.bind.annotation.RequestBody;
    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RequestParam;
    import org.springframework.web.bind.annotation.RestController;
    import org.springframework.web.util.UriComponentsBuilder;

    import microservice.workshop.bootdemo.data.PersonRepository;
    import microservice.workshop.bootdemo.model.Person;

    @RestController
    @RequestMapping("/person")
    public class PersonController {

        @Autowired
        private PersonRepository personRepository;

        @GetMapping
        public ResponseEntity<List<Person>> findAll() {
            return ResponseEntity.ok(personRepository.findAll());
        }

        @GetMapping("/{id}")
        public ResponseEntity<Person> findById(@PathVariable("id") Integer id) {
            return ResponseEntity.of(personRepository.findById(id));
        }

        @GetMapping("/search")
        public ResponseEntity<List<Person>> search(@RequestParam("lastName") String lastName) {
            return ResponseEntity.ok(personRepository.findByLastName(lastName));
        }

        @PostMapping
        public ResponseEntity<?> insert(@RequestBody Person person, UriComponentsBuilder ucBuilder) {
            Optional<Person> op = personRepository.findByFirstNameAndLastName(person.getFirstName(), person.getLastName());
            if (op.isPresent()) {
                return new ResponseEntity<>(HttpStatus.CONFLICT);
            }

            person = personRepository.save(person);

            HttpHeaders headers = new HttpHeaders();
            headers.setLocation(ucBuilder.path("/person/{id}").buildAndExpand(person.getId()).toUri());
            return new ResponseEntity<>(headers, HttpStatus.CREATED);
        }

        @PutMapping("/{id}")
        public ResponseEntity<Person> update(@PathVariable("id") Integer id, @RequestBody Person person) {
            return personRepository.findById(id).map(p -> {
                p.setLastName(person.getFirstName());
                p.setLastName(person.getLastName());
                personRepository.save(p);
                return new ResponseEntity<>(p, HttpStatus.OK);
            }).orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
        }

        @DeleteMapping("/{id}")
        public ResponseEntity<?> delete(@PathVariable("id") Integer id) {
            return personRepository.findById(id).map(p -> {
                personRepository.delete(p);
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }).orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
        }
    }
    ```

    This controller makes use of the `PersonRepository` to do interaction with the database. Notice the use of the `@Autowired` annotation
    which is for property-based dependency injection. Spring now recommends using constructor based DI, but you will likely find
    `@Autowired` annotations in lots of older code bases.

    In this controller you see HTTP request mappings for various methods (GET, POST, DELETE, etc.) You also see `@PathVariable` annotations
    to pull method variables off a URL path. Finally, notice the use of the `ResponseEntity` - this allows us to set different HTTP return
    codes and response headers.

### Unit Tests

1. Make a new package `microservice.workshop.bootdemo.controller` in the `src/test/java` tree
1. Create a class in the new package called `PersonControllerTest`
1. Set the content of `PersonControllerTest` to the following:

    ```java
    package microservice.workshop.jpademo.http;
    
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
    public class PersonControllerTest {
        private MockMvc mockMvc;
    
        @Autowired
        private WebApplicationContext webApplicationContext;
    
        @BeforeEach
        public void setup() {
            this.mockMvc = webAppContextSetup(webApplicationContext).build();
        }
    
        @Test
        public void testFindAll() throws Exception {
            mockMvc.perform(get("/person"))
            .andExpect(status().is(HttpStatus.OK.value()))
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$", hasSize(4)));
        }

        @Test
        public void testFindOne() throws Exception {
            mockMvc.perform(get("/person/1"))
            .andExpect(status().is(HttpStatus.OK.value()))
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.firstName", is("Fred")))
            .andExpect(jsonPath("$.lastName", is("Flintstone")));
        }

        @Test
        public void testFindNone() throws Exception {
            mockMvc.perform(get("/person/22"))
            .andExpect(status().is(HttpStatus.NOT_FOUND.value()));
        }

        @Test
        public void testSearch() throws Exception {
            mockMvc.perform(get("/person/search?lastName=Rubble"))
            .andExpect(status().is(HttpStatus.OK.value()))
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$", hasSize(2)));
        }    
    }
    ```

### Testing

1. Run the unit tests:
    - (Windows Command Prompt) `mvnw clean test`
    - (Windows Powershell) `.\mvnw clean test`
    - (Mac/Linux) `./mvnw clean test`
    - Or your IDE's method of running tests

1. Start the application
1. Test Swagger [http://localhost:8080](http://localhost:8080) - your new endpoint should be in Swagger

## Run in Docker

Spring Boot includes tools for building container images. Images are built using Cloud Native Buildpacks (https://buildpacks.io/).
Cloud native buildpacks are a CNCF project and are now the CNCF recommended method for building container images.

Build a container image using Maven:
    - (Windows Command Prompt) `mvnw clean spring-boot:build-image`
    - (Windows Powershell) `.\mvnw clean spring-boot:build-image`
    - (Mac/Linux) `./mvnw clean spring-boot:build-image`

Note that this command requires that Docker is installed on the machine where the command is run.

By default this will create an image named `boot-demo` (the Maven project name) with version `0.0.1-SNAPSHOT` (the Maven project version).

You can run this image in Docker with the following command:

```shell
docker run -p 8080:8080 boot-demo:0.0.1-SNAPSHOT
```

This will run the image in a command window. If you want to run it in the background (as a daemon), use the `-d` flag.
