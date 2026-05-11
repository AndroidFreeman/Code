package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.Student;
import com.androidfreeman.lifesbeengood.repository.StudentRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/students")
@CrossOrigin(origins = "*", maxAge = 3600)
public class StudentController {

    @Autowired private StudentRepository studentRepository;
    @Autowired private EventService eventService;

    @GetMapping
    @Cacheable("students")
    public ApiResponse<List<Student>> listStudents() {
        return ApiResponse.success(studentRepository.findAll());
    }

    @PostMapping
    @CacheEvict(value = "students", allEntries = true)
    public ApiResponse<Student> insertStudent(@RequestBody Student student) {
        if (student.getId() == null || student.getId().isEmpty()) {
            student.setId(UUID.randomUUID().toString());
        }
        Student saved = studentRepository.save(student);
        eventService.emitModulesChanged("students");
        return ApiResponse.success(saved);
    }

    @DeleteMapping
    @CacheEvict(value = "students", allEntries = true)
    public ApiResponse<String> deleteStudent(@RequestParam("full_name") String fullName, @RequestParam("student_no") String studentNo) {
        Optional<Student> student = studentRepository.findByFullNameAndStudentNo(fullName, studentNo);
        if (student.isPresent()) {
            studentRepository.delete(student.get());
            eventService.emitModulesChanged("students");
            return ApiResponse.success("Deleted");
        }
        return ApiResponse.error("Student not found");
    }
}