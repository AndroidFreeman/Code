package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.AttendanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, String> {
    List<AttendanceRecord> findBySessionIdAndStudentId(String sessionId, String studentId);
    List<AttendanceRecord> findBySessionId(String sessionId);
}
