package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.model.ScheduleEvent;
import com.androidfreeman.lifesbeengood.model.TimetableItem;
import com.androidfreeman.lifesbeengood.repository.ScheduleEventRepository;
import com.androidfreeman.lifesbeengood.repository.TimetableItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*", maxAge = 3600)
public class SyncController {

    @Autowired
    private TimetableItemRepository timetableItemRepository;

    @Autowired
    private ScheduleEventRepository scheduleEventRepository;

    @GetMapping("/sync")
    public ApiResponse<Map<String, Object>> syncData(
            @RequestParam(defaultValue = "0") long since,
            @RequestHeader(value = "Authorization", required = false) String token) {
        
        String ownerProfileId = extractProfileId(token);
        
        List<TimetableItem> timetable = timetableItemRepository.findByOwnerProfileIdAndUpdatedAtGreaterThan(ownerProfileId, since);
        List<ScheduleEvent> schedules = scheduleEventRepository.findByOwnerProfileIdAndUpdatedAtGreaterThan(ownerProfileId, since);
        
        Map<String, Object> data = new HashMap<>();
        data.put("timetable", timetable);
        data.put("schedules", schedules);
        data.put("timestamp", System.currentTimeMillis());
        
        return ApiResponse.success(data);
    }

    private String extractProfileId(String token) {
        if (token != null && token.startsWith("Bearer ")) {
            return token.substring(7).split(":")[0];
        }
        return "unknown";
    }
}