package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.TimetableItem;
import com.androidfreeman.lifesbeengood.repository.TimetableItemRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/timetable")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class TimetableController {

    private final TimetableItemRepository timetableItemRepository;
    private final EventService eventService;

    @GetMapping
    @Cacheable("timetable")
    public ApiResponse<List<TimetableItem>> listTimetable() {
        return ApiResponse.success(timetableItemRepository.findAll());
    }

    @PostMapping
    @CacheEvict(value = "timetable", allEntries = true)
    public ApiResponse<TimetableItem> insertTimetableItem(@RequestBody TimetableItem item) {
        if (item.getId() == null || item.getId().isEmpty()) {
            item.setId(UUID.randomUUID().toString());
        }
        TimetableItem saved = timetableItemRepository.save(item);
        eventService.emitModulesChanged("timetable");
        return ApiResponse.success(saved);
    }

    @DeleteMapping
    @CacheEvict(value = "timetable", allEntries = true)
    @org.springframework.transaction.annotation.Transactional
    public ApiResponse<String> deleteTimetableCondition(
            @RequestParam("owner_profile_id") String ownerProfileId,
            @RequestParam(value = "weekday", required = false) Integer weekday,
            @RequestParam(value = "start_period", required = false) Integer startPeriod,
            @RequestParam(value = "created_by_profile_id", required = false) String createdByProfileId) {
        
        if (weekday == null || startPeriod == null) {
            // If weekday or startPeriod is not provided, clear all for the given owner
            timetableItemRepository.deleteByOwnerProfileId(ownerProfileId);
        } else if (createdByProfileId != null && !createdByProfileId.isEmpty()) {
            timetableItemRepository.deleteByOwnerProfileIdAndWeekdayAndStartPeriodAndCreatedByProfileId(ownerProfileId, weekday, startPeriod, createdByProfileId);
        } else {
            timetableItemRepository.deleteByOwnerProfileIdAndWeekdayAndStartPeriod(ownerProfileId, weekday, startPeriod);
        }
        eventService.emitModulesChanged("timetable");
        return ApiResponse.success("Deleted");
    }
}