package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "todos")
public class TodoItem implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String ownerProfileId;
    private String folder;
    private String title;
    private boolean isDone;
    private String dueAt;
    private String createdAt;
    private String updatedAt;
}
