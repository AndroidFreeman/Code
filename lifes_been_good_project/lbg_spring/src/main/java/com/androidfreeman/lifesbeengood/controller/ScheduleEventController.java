package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.model.ScheduleEvent;
import com.androidfreeman.lifesbeengood.repository.ScheduleEventRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedules")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ScheduleEventController {

    @Autowired
    private ScheduleEventRepository scheduleEventRepository;

    @Autowired
    private EventService eventService;

    @GetMapping
    public ApiResponse<List<ScheduleEvent>> getSchedules(@RequestHeader(value = "Authorization", required = false) String token) {
        String ownerProfileId = extractProfileId(token);
        return ApiResponse.success(scheduleEventRepository.findByOwnerProfileId(ownerProfileId));
    }

    @PostMapping
    public ApiResponse<ScheduleEvent> createSchedule(@RequestBody ScheduleEvent event, @RequestHeader(value = "Authorization", required = false) String token) {
        String ownerProfileId = extractProfileId(token);
        event.setOwnerProfileId(ownerProfileId);
        ScheduleEvent saved = scheduleEventRepository.save(event);
        eventService.emitModulesChanged("schedules");
        return ApiResponse.success(saved);
    }

    @PutMapping("/{id}")
    public ApiResponse<ScheduleEvent> updateSchedule(@PathVariable String id, @RequestBody ScheduleEvent event, @RequestHeader(value = "Authorization", required = false) String token) {
        String ownerProfileId = extractProfileId(token);
        event.setId(id);
        event.setOwnerProfileId(ownerProfileId);
        ScheduleEvent saved = scheduleEventRepository.save(event);
        eventService.emitModulesChanged("schedules");
        return ApiResponse.success(saved);
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteSchedule(@PathVariable String id) {
        scheduleEventRepository.deleteById(id);
        eventService.emitModulesChanged("schedules");
        return ApiResponse.success(null);
    }

    private String extractProfileId(String token) {
        if (token != null && token.startsWith("Bearer ")) {
            return token.substring(7).split(":")[0];
        }
        return "unknown";
    }
}