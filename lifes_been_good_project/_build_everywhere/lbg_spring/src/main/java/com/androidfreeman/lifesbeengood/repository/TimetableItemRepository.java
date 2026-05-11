package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.TimetableItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface TimetableItemRepository extends JpaRepository<TimetableItem, String> {
    @Transactional
    void deleteByOwnerProfileIdAndWeekdayAndStartPeriod(String ownerProfileId, int weekday, int startPeriod);
    
    @Transactional
    void deleteByOwnerProfileIdAndWeekdayAndStartPeriodAndCreatedByProfileId(String ownerProfileId, int weekday, int startPeriod, String createdByProfileId);
    
    @Transactional
    void deleteByOwnerProfileId(String ownerProfileId);
    
    java.util.List<TimetableItem> findByOwnerProfileId(String ownerProfileId);
}
