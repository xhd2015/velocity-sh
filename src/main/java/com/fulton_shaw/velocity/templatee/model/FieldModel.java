package com.fulton_shaw.velocity.templatee.model;

import com.fulton_shaw.velocity.templatee.PojoUtils;

/**
 * @author xiaohuadong
 * @date 2019/06/07
 */
public class FieldModel {
    private String typePackage;
    private String typeName;
    private String name;

    public String getTypePackage() {
        return typePackage;
    }

    public void setTypePackage(String typePackage) {
        this.typePackage = typePackage;
    }

    public String getTypeName() {
        return typeName;
    }

    public void setTypeName(String typeName) {
        this.typeName = typeName;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }


    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("FieldModel{");
        sb.append("typePackage='").append(typePackage).append('\'');
        sb.append(", typeName='").append(typeName).append('\'');
        sb.append(", name='").append(name).append('\'');
        sb.append('}');
        return sb.toString();
    }
}
