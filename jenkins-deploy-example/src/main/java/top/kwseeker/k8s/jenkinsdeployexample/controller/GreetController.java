package top.kwseeker.k8s.jenkinsdeployexample.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class GreetController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello, This is a case for test Jenkins CI/CD";
    }
}
