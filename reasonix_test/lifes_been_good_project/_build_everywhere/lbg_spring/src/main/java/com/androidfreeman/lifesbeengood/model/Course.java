package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "courses")
public class Course implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String courseName;
    private String teacherProfileId;
    private String termCode;
    private String color;
    private String credits;
    private String notes;
}
