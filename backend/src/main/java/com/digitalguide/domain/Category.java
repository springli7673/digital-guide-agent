package com.digitalguide.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("biz.category")
public class Category {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String code;
    private String name;
    /** 类目参数定义（JSON 字符串，对应 jsonb 列） */
    private String specSchema;
    private Integer sort;
}
