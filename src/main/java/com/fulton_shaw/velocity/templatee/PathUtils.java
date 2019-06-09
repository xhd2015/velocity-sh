package com.fulton_shaw.velocity.templatee;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;

/**
 * @author xiaohuadong
 * @date 2019/06/06
 */
public class PathUtils {

    public static String correctPath(String path) {
        return correctPath(path, System.getenv("OSTYPE"));
    }

    public static String correctPath(String path, String ostype) {
        if (path == null) {
            return null;
        }
        if ("cygwin".equals(ostype) || "cygwin32".equals(ostype)) {
            try {
                Process process = Runtime.getRuntime().exec(new String[]{"cygpath", "--windows", path});
                int code = process.waitFor();
                if (code != 0) {
                    throw new RuntimeException("cannot convert path:" + path + " to windows path");
                }
                String winPath = IOUtils.toString(process.getInputStream(), StandardCharsets.UTF_8);
                return winPath;
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
        return path;
    }
}
