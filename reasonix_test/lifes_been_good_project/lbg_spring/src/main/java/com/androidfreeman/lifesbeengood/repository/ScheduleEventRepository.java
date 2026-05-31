package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.ScheduleEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ScheduleEventRepository extends JpaRepository<ScheduleEvent, String> {
    List<ScheduleEvent> findByOwnerProfileId(String ownerProfileId);
    List<ScheduleEvent> findByOwnerProfileIdAndUpdatedAtGreaterThan(String ownerProfileId, long timestamp);
}