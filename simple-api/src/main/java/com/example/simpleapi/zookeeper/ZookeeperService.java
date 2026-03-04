package com.example.simpleapi.zookeeper;

import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.retry.ExponentialBackoffRetry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

@Service
public class ZookeeperService {

    private static final Logger log = LoggerFactory.getLogger(ZookeeperService.class);

    @Value("${zookeeper.connect:localhost:2181}")
    private String connectString;

    @Value("${zookeeper.node:/app/config}")
    private String configNode;

    @Value("${zookeeper.default-value:default-from-zk}")
    private String defaultValue;

    private CuratorFramework client;

    @PostConstruct
    public void init() {
        if (connectString == null || connectString.isEmpty()) {
            log.warn("Zookeeper connect string not set, Zookeeper features disabled");
            return;
        }
        try {
            client = CuratorFrameworkFactory.builder()
                    .connectString(connectString)
                    .connectionTimeoutMs(5000)
                    .sessionTimeoutMs(10000)
                    .retryPolicy(new ExponentialBackoffRetry(1000, 3))
                    .build();
            client.start();
            client.blockUntilConnected(30, TimeUnit.SECONDS);
            ensureNodeExists();
            log.info("Connected to Zookeeper at {}", connectString);
        } catch (Exception e) {
            log.error("Failed to connect to Zookeeper: {}", e.getMessage());
        }
    }

    @PreDestroy
    public void shutdown() {
        if (client != null) {
            client.close();
        }
    }

    private void ensureNodeExists() throws Exception {
        if (client.checkExists().forPath(configNode) == null) {
            client.create().creatingParentsIfNeeded().forPath(configNode, defaultValue.getBytes(StandardCharsets.UTF_8));
            log.info("Created Zookeeper node {} with default value", configNode);
        }
    }

    public String getConfigValue() {
        if (client == null) {
            return "Zookeeper not configured";
        }
        try {
            byte[] data = client.getData().forPath(configNode);
            return data != null ? new String(data, StandardCharsets.UTF_8) : "";
        } catch (Exception e) {
            log.error("Failed to read from Zookeeper: {}", e.getMessage());
            return "Error: " + e.getMessage();
        }
    }
}
