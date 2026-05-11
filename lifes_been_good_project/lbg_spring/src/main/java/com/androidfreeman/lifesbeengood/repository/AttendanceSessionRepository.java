package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.AttendanceSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AttendanceSessionRepository extends JpaRepository<AttendanceSession, String> {
}
