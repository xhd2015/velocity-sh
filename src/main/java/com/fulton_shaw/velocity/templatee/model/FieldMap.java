package com.fulton_shaw.velocity.templatee.model;

/**
 * @author xiaohuadong
 * @date 2019/06/07
 */
public class FieldMap {
    private String dbName;
    private String javaName;

    public String getDbName() {
        return dbName;
    }

    public void setDbName(String dbName) {
        this.dbName = dbName;
    }

    public String getJavaName() {
        return javaName;
    }

    public void setJavaName(String javaName) {
        this.javaName = javaName;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("FieldMap{");
        sb.append("dbName='").append(dbName).append('\'');
        sb.append(", javaName='").append(javaName).append('\'');
        sb.append('}');
        return sb.toString();
    }
}
