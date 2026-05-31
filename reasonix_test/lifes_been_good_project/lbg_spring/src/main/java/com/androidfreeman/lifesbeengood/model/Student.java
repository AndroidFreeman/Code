package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "students", indexes = {
    @Index(name = "idx_student_no", columnList = "studentNo"),
    @Index(name = "idx_student_class", columnList = "classCode")
})
public class Student implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String studentNo;
    private String fullName;
    private String pinyin;
    private String gender;
    private String classCode;
    private String className;
    private String phone;
    private String position;
}
