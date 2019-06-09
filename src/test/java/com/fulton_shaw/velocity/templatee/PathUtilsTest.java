package com.fulton_shaw.velocity.templatee;

import org.junit.Test;
import org.junit.runner.RunWith;

/**
 * @author xiaohuadong
 * @date 2019/06/06
 */
public class PathUtilsTest {
    @Test
    public void testPathConv() {
        String cygwin = PathUtils.correctPath("../ui", "cygwin");
        System.out.println(cygwin);
    }
}
