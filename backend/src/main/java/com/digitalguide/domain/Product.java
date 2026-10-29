package com.digitalguide.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Data
@TableName("biz.product")
public class Product {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long brandId;
    private Long categoryId;
    private String model;
    private String title;
    private LocalDate launchDate;
    private BigDecimal priceRef;
    private String priceSource;
    private OffsetDateTime priceUpdatedAt;
    /** {"display":{...},"metrics":{...}} */
    private String specs;
    /** 卖点标签数组（JSON 字符串） */
    private String highlights;
    private String imageUrl;
    private String dataSource;
    private String status;
    private OffsetDateTime createdAt;
}
