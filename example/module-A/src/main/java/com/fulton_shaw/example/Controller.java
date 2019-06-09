package com.fulton_shaw.example;

public class Controller {

    private String name;

    public String getName() {
        return name;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("Controller{");
        sb.append("name='").append(name).append('\'');
        sb.append('}');
        return sb.toString();
    }
}