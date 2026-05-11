package com.androidfreeman.lifesbeengood.model;

import jakarta.persistence.*;
import lombok.Data;

import java.io.Serializable;

@Data
@Entity
@Table(name = "qrcodes")
public class QrCode implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    private String id;
    private String name;
    
    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String path;
}