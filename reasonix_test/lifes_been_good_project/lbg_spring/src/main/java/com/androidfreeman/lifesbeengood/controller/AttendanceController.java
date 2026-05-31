package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.AttendanceRecord;
import com.androidfreeman.lifesbeengood.model.AttendanceSession;
import com.androidfreeman.lifesbeengood.model.Student;
import com.androidfreeman.lifesbeengood.repository.AttendanceRecordRepository;
import com.androidfreeman.lifesbeengood.repository.AttendanceSessionRepository;
import com.androidfreeman.lifesbeengood.repository.StudentRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.ArrayList;

@RestController
@RequestMapping("/api/attendance")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceSessionRepository attendanceSessionRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final StudentRepository studentRepository;
    private final EventService eventService;

    @GetMapping("/sessions")
    public ApiResponse<List<AttendanceSession>> listAttendanceSessions() {
        return ApiResponse.success(attendanceSessionRepository.findAll());
    }

    @GetMapping("/records")
    public ApiResponse<List<AttendanceRecord>> listAttendanceRecords() {
        return ApiResponse.success(attendanceRecordRepository.findAll());
    }

    @PostMapping("/sessions")
    @org.springframework.transaction.annotation.Transactional
    public ApiResponse<Map<String, String>> startAttendanceSession(@RequestBody AttendanceSession session) {
        String id = "as_" + System.currentTimeMillis();
        session.setId(id);
        session.setStartedAt(java.time.Instant.now().toString());
        attendanceSessionRepository.save(session);
        eventService.emitModulesChanged("attendance");
        return ApiResponse.success(Map.of("session_id", id, "started_at", session.getStartedAt()));
    }

    @PostMapping("/records")
    @org.springframework.transaction.annotation.Transactional
    public ApiResponse<AttendanceRecord> markAttendanceRecord(@RequestBody AttendanceRecord record) {
        List<AttendanceRecord> existing = attendanceRecordRepository.findBySessionIdAndStudentId(record.getSessionId(), record.getStudentId());
        if (!existing.isEmpty()) {
            AttendanceRecord r = existing.get(0);
            r.setStatus(record.getStatus());
            r.setMarkedByProfileId(record.getMarkedByProfileId());
            AttendanceRecord saved = attendanceRecordRepository.save(r);
            eventService.emitModulesChanged("attendance");
            return ApiResponse.success(saved);
        }
        AttendanceRecord saved = attendanceRecordRepository.save(record);
        eventService.emitModulesChanged("attendance");
        return ApiResponse.success(saved);
    }

    @PostMapping("/records/batch")
    @org.springframework.transaction.annotation.Transactional
    public ApiResponse<Map<String, Boolean>> batchMarkAttendanceRecords(@RequestBody Map<String, Object> payload) {
        String sessionId = (String) payload.get("session_id");
        String status = (String) payload.get("status");
        String markedByProfileId = (String) payload.get("marked_by_profile_id");
        Object studentIdsObj = payload.get("student_ids");
        if (!(studentIdsObj instanceof List<?>)) {
            return ApiResponse.error("student_ids must be a list");
        }
        List<String> studentIds = ((List<?>) studentIdsObj).stream()
                .map(Object::toString)
                .collect(java.util.stream.Collectors.toList());

        if (sessionId == null || status == null || studentIds.isEmpty()) {
            return ApiResponse.error("Missing required fields");
        }

        List<AttendanceRecord> existingRecords = attendanceRecordRepository.findBySessionId(sessionId);
        Map<String, AttendanceRecord> recordMap = existingRecords.stream()
                .collect(java.util.stream.Collectors.toMap(AttendanceRecord::getStudentId, r -> r, (existing, replacement) -> existing));

        List<AttendanceRecord> toSave = new ArrayList<>();
        for (String studentId : studentIds) {
            AttendanceRecord r = recordMap.getOrDefault(studentId, new AttendanceRecord());
            if (r.getId() == null) {
                r.setSessionId(sessionId);
                r.setStudentId(studentId);
            }
            r.setStatus(status);
            r.setMarkedByProfileId(markedByProfileId);
            toSave.add(r);
        }
        attendanceRecordRepository.saveAll(toSave);
        eventService.emitModulesChanged("attendance");
        return ApiResponse.success(Map.of("ok", true));
    }

    /**
     * Face recognition endpoint — CURRENTLY A MOCK/STUB.
     * TODO: Replace with actual MLKit / face recognition integration.
     * Currently returns a random student for demo purposes only.
     */
    @PostMapping("/recognize")
    public ApiResponse<List<String>> recognizeFace(@RequestParam("file") MultipartFile file, @RequestParam("sessionId") String sessionId) {
        // Validate file is not empty
        if (file == null || file.isEmpty()) {
            return ApiResponse.error("No file uploaded");
        }
        // MOCK: returns a random student — replace with real face recognition
        List<Student> allStudents = studentRepository.findAll();
        if (allStudents.isEmpty()) {
            return ApiResponse.success(Collections.emptyList());
        }
        Random rand = new Random();
        int index = rand.nextInt(allStudents.size());
        Student recognizedStudent = allStudents.get(index);
        return ApiResponse.success(Collections.singletonList(recognizedStudent.getId()));
    }
}