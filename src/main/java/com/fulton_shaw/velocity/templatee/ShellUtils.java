package com.fulton_shaw.velocity.templatee;

import org.apache.commons.io.IOUtils;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

/**
 * example:
 *    $ShellUtils.exec("D:\installed\cygwin\bin\bash","-c","cygpath d:") $ShellUtils.errno()
 *  output:
 *   /cygdrive/d 0
 * @author xiaohuadong
 * @date 2019/06/09
 */
public class ShellUtils {

    public static final int ERR_TIMEOUT = 127;
    public static final int ERR_JVM = 128;

    private ShellUtils() {
    }

    private static int lastErrno = 0;

    public static int errno() {
        return lastErrno;
    }

    public static String exec(String... args) {
        lastErrno = 0;
        try {
            Process process = Runtime.getRuntime().exec(args);
            boolean completed = process.waitFor(30, TimeUnit.SECONDS);
            if (!completed) {
                lastErrno = ERR_TIMEOUT;
                return null;
            } else {
                lastErrno = process.exitValue();
                return IOUtils.toString(process.getInputStream(), StandardCharsets.UTF_8);
            }
        } catch (Exception e) {
            lastErrno = ERR_JVM;
            throw new RuntimeException(e);
        }
    }
}
