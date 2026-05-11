package com.androidfreeman.lifesbeengood.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "school_classes")
public class SchoolClass implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id; // This is the classCode
    
    @JsonProperty("className")
    private String className;
    
    @JsonProperty("joinPassword")
    private String joinPassword;
    
    @JsonProperty("createdByProfileId")
    private String createdByProfileId;
}
