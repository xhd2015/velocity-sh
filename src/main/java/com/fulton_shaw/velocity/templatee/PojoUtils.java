package com.fulton_shaw.velocity.templatee;

import com.fulton_shaw.velocity.templatee.model.FieldMap;
import com.fulton_shaw.velocity.templatee.model.FieldModel;
import org.apache.commons.lang3.StringUtils;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * @author xiaohuadong
 * @date 2019/06/07
 */
public class PojoUtils {
    private PojoUtils() {
    }

    public static String getPackage(String fqn) {
        if (fqn == null) {
            return null;
        }
        int idx = fqn.lastIndexOf('.');
        if (idx == -1) {
            return "";
        }
        return fqn.substring(0, idx);
    }

    public static String getShortName(String fqn) {
        if (fqn == null) {
            return null;
        }
        int idx = fqn.lastIndexOf('.');
        return idx == -1 ? fqn : fqn.substring(idx + 1);
    }

    public static String capitalize(String s) {
        return s == null || s.isEmpty() ? s : s.substring(0, 1).toUpperCase() + (s.length() > 1 ? s.substring(1) : "");
    }

    public static String toCamelCase(List<String> words) {
        return (words.size() > 0 ? words.get(0).toLowerCase() : "") +
                (words.size() > 1 ? StringUtils.join(words.subList(1, words.size()).stream().map(s -> capitalize(s)).collect(Collectors.toList()), "") : "");
    }

    public static String toUnderScoreCase(List<String> words) {
        return StringUtils.join(words.stream().map(String::toLowerCase).collect(Collectors.toList()), '_');
    }

    public static String toCamelCase(String s) {
        if (StringUtils.isEmpty(s) || ParamUtils.isCamelCase(s)) {
            return s;
        }
        return toCamelCase(ParamUtils.splitWords(s));
    }

    public static String toUnderScoreCase(String s) {
        if (StringUtils.isEmpty(s) || ParamUtils.isUnderScoreCase(s)) {
            return s;
        }
        return toUnderScoreCase(ParamUtils.splitWords(s));
    }

    public static List<FieldModel> parseFields(String fields) {
        if (fields == null || fields.isEmpty()) {
            return Collections.emptyList();
        }
        List<FieldModel> result = new ArrayList<>();
        String[] f = fields.split("\\s*,\\s*");
        for (String s : f) {
            if (s.isEmpty()) {
                continue;
            }
            String[] typeValue = s.split("\\s+");
            if (typeValue.length != 2) {
                throw new IllegalArgumentException("format invalid:requires TYPE NAME");
            }
            FieldModel fieldModel = new FieldModel();
            String pkg = PojoUtils.getPackage(typeValue[0]);
            String shortName = PojoUtils.getShortName(typeValue[0]);
            if (StringUtils.isEmpty(pkg)) {
                try {
                    // try java.lang
                    Class.forName("java.lang." + shortName);
                    pkg = "java.lang";
                } catch (Exception e) {
                    // else unset
                }
            }
            fieldModel.setTypePackage(pkg);
            fieldModel.setTypeName(shortName);
            fieldModel.setName(typeValue[1]);
            result.add(fieldModel);
        }
        return result;
    }

    public static List<FieldMap> parseFieldMap(String fieldMap) {
        List<List<String>> lists = ParamUtils.parseList(ParamUtils.COMMA_SEP, "\\s+", fieldMap);
        List<FieldMap> fieldsMap = new ArrayList<>();
        for (List<String> list : lists) {
            String dbName = null;
            String javaName = null;
            if (list.size() == 1) {
                List<String> words = ParamUtils.splitWords(list.get(0));
                dbName = toUnderScoreCase(words);
                javaName = toCamelCase(words);
            } else if (list.size() == 2) {
                dbName = list.get(0);
                javaName = list.get(1);
            } else {
                throw new IllegalArgumentException("field map format error:" + fieldMap);
            }
            FieldMap m = new FieldMap();
            m.setDbName(dbName);
            m.setJavaName(javaName);
            fieldsMap.add(m);
        }
        return fieldsMap;
    }

    /**
     * get field value using getter or field
     *
     * @param o
     * @param field
     * @return
     */
    public static Object getValue(Object o, String field) {
        if (o == null) {
            return null;
        }
        if (StringUtils.isEmpty(field)) {
            throw new IllegalArgumentException("filed cannot be empty");
        }
        String getter = "get" + capitalize(field);
        Method getterMethod = null;
        Field getterField = null;
        try {
            getterMethod = o.getClass().getDeclaredMethod(getter);
            getterMethod.setAccessible(true);
        } catch (NoSuchMethodException e) {
            // no method
            try {
                getterField = o.getClass().getDeclaredField(field);
                getterField.setAccessible(true);
            } catch (NoSuchFieldException e1) {
                throw new IllegalArgumentException("cannot find field:" + field + " of class:" + o.getClass().getName());
            }
        }
        Exception reason = null;
        try {
            if (getterMethod != null) {
                return getterMethod.invoke(o);
            } else if (getterField != null) {
                return getterField.get(o);
            }
        } catch (Exception e) {
            reason = e;
        }
        throw new RuntimeException("cannot access field:" + field + " of class:" + o.getClass().getName(), reason);
    }
}
