package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "timetable", indexes = {
    @Index(name = "idx_timetable_owner", columnList = "ownerProfileId"),
    @Index(name = "idx_timetable_course", columnList = "courseId"),
    @Index(name = "idx_timetable_weekday", columnList = "weekday")
})
public class TimetableItem implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String ownerProfileId;
    private int weekday;
    private int startPeriod;
    private int endPeriod;
    private String startTime;
    private String endTime;
    private String courseId;
    private String location;
    private String createdByProfileId;
    private boolean isLocked;
    private String weeks;
    private long updatedAt;

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        updatedAt = System.currentTimeMillis();
    }
}
