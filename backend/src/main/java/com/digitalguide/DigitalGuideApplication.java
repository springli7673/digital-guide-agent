package com.digitalguide;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.digitalguide.mapper")
public class DigitalGuideApplication {

    public static void main(String[] args) {
        SpringApplication.run(DigitalGuideApplication.class, args);
    }
}
