package com.fulton_shaw.example.query;

public class QueryModel{
    private Long id;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("QueryModel{");
        sb.append("id=").append(id);
        sb.append('}');
        return sb.toString();
    }
}