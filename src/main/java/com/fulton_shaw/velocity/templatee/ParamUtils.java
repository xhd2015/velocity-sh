package com.fulton_shaw.velocity.templatee;

import org.apache.commons.lang3.StringUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * @author xiaohuadong
 * @date 2019/06/07
 */
public class ParamUtils {
    public static final String COMMA_SEP = "\\s*,\\s*";

    public static List<List<String>> parseList(String listSepRegex, String fieldSepRegex, String param) {
        List<List<String>> res = new ArrayList<List<String>>();
        if (StringUtils.isEmpty(param)) {
            return res;
        }
        for (String fields : param.split(listSepRegex)) {
            String[] splitFields = fields.split(fieldSepRegex);
            if (splitFields.length > 0) {
                res.add(new ArrayList<>(Arrays.asList(splitFields)));
            }
        }
        return res;
    }

    public static List<String> parseSimpleList(String param) {
        return parseSimpleList(param, COMMA_SEP);
    }

    public static List<String> parseSimpleList(String param, String regex) {
        return StringUtils.isEmpty(param) ? new ArrayList<>() : new ArrayList<>(Arrays.asList(param.split(regex)));
    }

    public static String recoveryShellParam(String[] args) {
        StringBuilder s = new StringBuilder();
        String joiner = " ";
        int i = 0;
        for (String arg : args) {
            String escape = escapeForShell(arg);
            if (i > 0) {
                s.append(joiner);
            }
            s.append(escape);
            ++i;
        }
        return s.toString();
    }

    public static String escapeForShell(String s) {
        if (StringUtils.isEmpty(s)) {
            return "\"\"";
        }
        if (StringUtils.containsAny(s, "$\"'`<\n()\\ \t")) {
            return "'" + s.replace("'", "'\\''") + "'";
        } else {
            // verbatim
            return s;
        }
    }

    public static boolean isCamelCase(String id) {
        if (StringUtils.isEmpty(id)) {
            return false;
        }
        Pattern pattern = Pattern.compile("[A-Z]?[a-z0-9]+(?:[A-Z][a-z0-9]+)*");
        Matcher matcher = pattern.matcher(id);
        return matcher.matches();
    }

    public static boolean isUnderScoreCase(String id) {
        if (StringUtils.isEmpty(id)) {
            return false;
        }
        Pattern pattern = Pattern.compile("[A-Z]?[a-z0-9]+(?:_[a-z0-9]+)*");
        Matcher matcher = pattern.matcher(id);
        return matcher.matches();
    }

    public static List<String> splitWords(String id) {
        if (StringUtils.isEmpty(id)) {
            return Collections.emptyList();
        }
        if (isCamelCase(id)) {
            String[] res = id.split("(?=[A-Z])");
            return new ArrayList<String>(Arrays.asList(res));
        } else if (isUnderScoreCase(id)) {
            return new ArrayList<>(Arrays.asList(StringUtils.split(id, '_')));
        } else {
            return new ArrayList<>(Arrays.asList(id));
        }
    }
}
