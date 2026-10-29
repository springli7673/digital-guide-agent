package com.digitalguide.config;

import com.digitalguide.common.UuidTypeHandler;
import com.baomidou.mybatisplus.autoconfigure.ConfigurationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.UUID;

/**
 * 注册 UUID 类型处理器，避免 uuid 字段在 insert / select 时报
 * "Type handler was null on parameter mapping for property 'id'"。
 */
@Configuration
public class MybatisConfig {

    @Bean
    public ConfigurationCustomizer uuidTypeHandlerCustomizer() {
        return configuration ->
                configuration.getTypeHandlerRegistry().register(UUID.class, new UuidTypeHandler());
    }
}
