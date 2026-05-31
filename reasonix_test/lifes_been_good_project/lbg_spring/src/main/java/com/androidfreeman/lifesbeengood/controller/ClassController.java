package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.SchoolClass;
import com.androidfreeman.lifesbeengood.model.Student;
import com.androidfreeman.lifesbeengood.model.Profile;
import com.androidfreeman.lifesbeengood.model.TimetableItem;
import com.androidfreeman.lifesbeengood.repository.SchoolClassRepository;
import com.androidfreeman.lifesbeengood.repository.StudentRepository;
import com.androidfreeman.lifesbeengood.repository.ProfileRepository;
import com.androidfreeman.lifesbeengood.repository.TimetableItemRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/classes")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class ClassController {

    private final SchoolClassRepository schoolClassRepository;
    private final StudentRepository studentRepository;
    private final ProfileRepository profileRepository;
    private final TimetableItemRepository timetableItemRepository;
    private final EventService eventService;

    @GetMapping
    public ApiResponse<List<SchoolClass>> listClasses() {
        return ApiResponse.success(schoolClassRepository.findAll());
    }

    @PostMapping
    public ApiResponse<SchoolClass> createClass(@RequestBody SchoolClass schoolClass) {
        if (schoolClass.getClassName() != null && !schoolClass.getClassName().isEmpty()) {
            if (schoolClassRepository.existsByClassName(schoolClass.getClassName())) {
                return ApiResponse.error("班级名称已存在 (Class name already exists)");
            }
        }
        if (schoolClass.getId() == null || schoolClass.getId().isEmpty()) {
            schoolClass.setId(UUID.randomUUID().toString().substring(0, 6).toUpperCase());
        }
        SchoolClass saved = schoolClassRepository.save(schoolClass);
        eventService.emitModulesChanged("classes", "profiles");
        return ApiResponse.success(saved);
    }

    @PostMapping("/{id}/verify")
    public ApiResponse<Boolean> verifyClassPassword(@PathVariable String id, @RequestBody Map<String, String> payload) {
        Optional<SchoolClass> opt = schoolClassRepository.findById(id);
        if (opt.isEmpty()) {
            return ApiResponse.error("Class not found");
        }
        String storedPassword = opt.get().getJoinPassword();
        String providedPassword = payload.get("password");
        // Use Objects.equals to handle null safely
        if (java.util.Objects.equals(storedPassword, providedPassword)) {
            return ApiResponse.success(true);
        }
        return ApiResponse.error("Incorrect password");
    }

    @DeleteMapping("/{id}")
    @org.springframework.transaction.annotation.Transactional
    public ApiResponse<String> deleteClassGlobally(@PathVariable String id) {
        if (schoolClassRepository.existsById(id)) {
            schoolClassRepository.deleteById(id);
            
            List<TimetableItem> classTimetables = timetableItemRepository.findByOwnerProfileId("class_" + id);
            List<Student> students = studentRepository.findByClassCode(id);
            
            for (TimetableItem ct : classTimetables) {
                for (Student s : students) {
                    timetableItemRepository.deleteByOwnerProfileIdAndWeekdayAndStartPeriod(
                        s.getId(), ct.getWeekday(), ct.getStartPeriod());
                }
            }
            
            timetableItemRepository.deleteByOwnerProfileId("class_" + id);
            
            for (Student s : students) {
                s.setClassCode("");
                s.setClassName("");
                studentRepository.save(s);
            }
            
            List<Profile> profiles = profileRepository.findByClassCodeContaining(id);
            for (Profile p : profiles) {
                if ("student".equals(p.getRole()) || "cadre".equals(p.getRole())) {
                    if (id.equals(p.getClassCode())) {
                        p.setClassCode("");
                        profileRepository.save(p);
                    }
                } else if ("teacher".equals(p.getRole())) {
                    if (p.getClassCode() != null && p.getClassCode().contains(id)) {
                        String[] classes = p.getClassCode().split("\\|");
                        List<String> newClasses = new ArrayList<>();
                        for (String c : classes) {
                            if (!c.equals(id) && !c.isEmpty()) {
                                newClasses.add(c);
                            }
                        }
                        p.setClassCode(String.join("|", newClasses));
                        profileRepository.save(p);
                    }
                }
            }
            
            eventService.emitModulesChanged("classes", "students", "profiles", "timetable");
            return ApiResponse.success("Class deleted globally");
        }
        return ApiResponse.error("Class not found");
    }
}