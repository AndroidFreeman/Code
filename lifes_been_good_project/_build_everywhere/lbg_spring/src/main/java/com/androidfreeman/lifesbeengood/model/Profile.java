package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "profiles", indexes = {
    @Index(name = "idx_profile_role", columnList = "role"),
    @Index(name = "idx_profile_staff_no", columnList = "staffNo"),
    @Index(name = "idx_profile_student_no", columnList = "studentNo"),
    @Index(name = "idx_profile_class", columnList = "classCode")
})
public class Profile implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String role;
    private String staffNo;
    private String studentNo;
    private String displayName;
    private String realName;
    private String orgCode;
    private String classCode;
    private String passwordHash;
    private String phone;
    private String email;
    private String dorm;
    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String avatar;
    private String signature;
    private String position;
}
