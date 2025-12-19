package com.sankuai.inf.leaf.segment;

import com.sankuai.inf.leaf.IDGen;
import com.sankuai.inf.leaf.common.Result;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

@SpringJUnitConfig(locations = {"classpath:applicationContext.xml"})
public class SpringIDGenServiceTest {
    @Autowired
    IDGen idGen;

    @Test
    public void testGetId() {
        for (int i = 0; i < 100; i++) {
            Result r = idGen.get("leaf-segment-test");
            System.out.println(r);
        }
    }
}
