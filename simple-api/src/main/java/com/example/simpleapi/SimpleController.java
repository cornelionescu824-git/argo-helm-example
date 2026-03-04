package com.example.simpleapi;

import com.example.simpleapi.zookeeper.ZookeeperService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class SimpleController {

    @Value("${app.message:Hello from Simple API}")
    private String message;

    @Value("${app.environment:local}")
    private String environment;

    @Autowired(required = false)
    private ZookeeperService zookeeperService;

    @GetMapping("/hello")
    public Map<String, String> hello() {
        Map<String, String> result = new HashMap<>();
        result.put("message", message);
        result.put("environment", environment);
        result.put("status", "ok");
        return result;
    }

    @GetMapping("/config/zk")
    public Map<String, String> zookeeperConfig() {
        Map<String, String> result = new HashMap<>();
        if (zookeeperService != null) {
            result.put("value", zookeeperService.getConfigValue());
            result.put("source", "zookeeper");
        } else {
            result.put("value", "Zookeeper not configured");
            result.put("source", "none");
        }
        return result;
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        Map<String, String> result = new HashMap<>();
        result.put("status", "UP");
        return result;
    }
}
