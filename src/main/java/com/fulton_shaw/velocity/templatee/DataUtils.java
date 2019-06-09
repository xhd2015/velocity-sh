package com.fulton_shaw.velocity.templatee;

import org.apache.commons.lang3.StringUtils;

import java.util.*;

/**
 * @author xiaohuadong
 * @date 2019/06/07
 */
public class DataUtils {
    public static boolean isNull(Object v) {
        return v == null;
    }

    public static Object getNull() {
        return null;
    }

    public static <K, V> Map<K, V> buildMapWithKey(List<V> list, String field) {
        Map<K, V> map = new HashMap<>();
        for (V v : list) {
            K key = (K) PojoUtils.getValue(v, field);
            map.put(key, v);
        }
        return map;
    }

    public static <V> Set<V> newHashSet() {
        return new HashSet<>();
    }

    public static <K, V> Map<K, V> newHashMap() {
        return new HashMap<>();
    }

    public static <V> List<V> newArrayList() {
        return new ArrayList<>();
    }

    public static List<String> splitNewLine(String s) {
        if (StringUtils.isEmpty(s)) {
            return new ArrayList<>();
        }
        return new ArrayList<>(Arrays.asList(s.split("(?:\\r\\n|\\n)")));
    }

    public static String appendPrefixForEachLine(String s, String prefix) {
        if (StringUtils.isEmpty(prefix)) {
            return s;
        }
        List<String> strings = splitNewLine(s);
        StringBuilder stringBuilder = new StringBuilder();
        for (String string : strings) {
            stringBuilder.append(prefix).append(string).append("\n");
        }
        return stringBuilder.toString();
    }

}
