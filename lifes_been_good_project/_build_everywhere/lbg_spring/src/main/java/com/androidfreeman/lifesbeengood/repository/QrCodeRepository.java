package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.QrCode;
import org.springframework.data.jpa.repository.JpaRepository;

public interface QrCodeRepository extends JpaRepository<QrCode, String> {
}