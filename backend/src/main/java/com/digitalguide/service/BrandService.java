package com.digitalguide.service;

import com.digitalguide.domain.Brand;
import com.digitalguide.dto.BrandRequest;
import com.digitalguide.mapper.BrandMapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BrandService {

    private final BrandMapper brandMapper;

    public List<Brand> list() {
        return brandMapper.selectList(Wrappers.<Brand>lambdaQuery().orderByAsc(Brand::getName));
    }

    public Brand create(BrandRequest request) {
        Brand brand = new Brand();
        brand.setName(request.name());
        brand.setNameEn(request.nameEn());
        brand.setCountry(request.country());
        brand.setLogoUrl(request.logoUrl());
        brandMapper.insert(brand);
        return brand;
    }

    public Brand findByName(String name) {
        return brandMapper.selectOne(Wrappers.<Brand>lambdaQuery().eq(Brand::getName, name));
    }
}
