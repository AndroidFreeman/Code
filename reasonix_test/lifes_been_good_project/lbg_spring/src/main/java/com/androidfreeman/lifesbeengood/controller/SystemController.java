package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class SystemController {

    private final EventService eventService;

    @GetMapping("/ping")
    public ApiResponse<Object> ping() {
        return ApiResponse.success("pong");
    }

    @GetMapping("/system/init")
    public ApiResponse<Object> systemInit(@RequestParam(defaultValue = "false") boolean seed) {
        // Implement logic to insert initial dummy data if seed is true
        return ApiResponse.success("Initialized");
    }

    @GetMapping(value = "/events/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamEvents() {
        return eventService.createEmitter();
    }
}