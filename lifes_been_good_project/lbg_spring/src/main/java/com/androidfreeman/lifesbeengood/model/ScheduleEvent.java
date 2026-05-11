package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "schedule_event", indexes = {
    @Index(name = "idx_schedule_owner", columnList = "ownerProfileId")
})
public class ScheduleEvent implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String ownerProfileId;
    private String title;
    private String location;
    private String startTime;
    private String endTime;
    private String type;
    private String backgroundColor;
    private String note;
    private long updatedAt;

    @PrePersist
    @PreUpdate
    protected void onUpdate() {
        updatedAt = System.currentTimeMillis();
    }
}