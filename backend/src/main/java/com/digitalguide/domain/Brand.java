package com.digitalguide.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("biz.brand")
public class Brand {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String name;
    private String nameEn;
    private String country;
    private String logoUrl;
}
