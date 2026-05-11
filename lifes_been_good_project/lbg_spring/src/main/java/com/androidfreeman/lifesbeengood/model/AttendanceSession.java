package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "attendance_sessions", indexes = {
    @Index(name = "idx_attsess_course", columnList = "courseId"),
    @Index(name = "idx_attsess_creator", columnList = "createdByProfileId")
})
public class AttendanceSession implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String courseId;
    private String createdByProfileId;
    private String startedAt;
    private String endedAt;
    private Integer week;
    private Integer period;
}
