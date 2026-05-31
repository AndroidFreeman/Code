package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "attendance_records", indexes = {
    @Index(name = "idx_attrec_session", columnList = "sessionId"),
    @Index(name = "idx_attrec_student", columnList = "studentId")
})
public class AttendanceRecord implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    private String sessionId;
    private String studentId;
    private String status;
    private String markedByProfileId;
}
