package com.androidfreeman.lifesbeengood.service;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class EventService {

    private final List<SseEmitter> eventEmitters = new CopyOnWriteArrayList<>();

    public SseEmitter createEmitter() {
        SseEmitter emitter = new SseEmitter(0L);
        eventEmitters.add(emitter);
        emitter.onCompletion(() -> eventEmitters.remove(emitter));
        emitter.onTimeout(() -> eventEmitters.remove(emitter));
        emitter.onError((ex) -> eventEmitters.remove(emitter));
        try {
            emitter.send(SseEmitter.event()
                    .name("sync")
                    .data(Map.of(
                            "modules", List.of("all"),
                            "ts", System.currentTimeMillis()
                    )));
        } catch (Exception ex) {
            emitter.complete();
            eventEmitters.remove(emitter);
        }
        return emitter;
    }

    public void emitModulesChanged(String... modules) {
        if (eventEmitters.isEmpty()) return;
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("modules", Arrays.asList(modules));
        payload.put("ts", System.currentTimeMillis());
        for (SseEmitter emitter : eventEmitters) {
            try {
                emitter.send(SseEmitter.event().name("sync").data(payload));
            } catch (Exception ex) {
                emitter.complete();
                eventEmitters.remove(emitter);
            }
        }
    }
}