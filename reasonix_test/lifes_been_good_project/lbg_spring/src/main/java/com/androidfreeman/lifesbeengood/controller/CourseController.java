package com.androidfreeman.lifesbeengood.controller;

import com.androidfreeman.lifesbeengood.controller.ApiResponse;
import com.androidfreeman.lifesbeengood.model.Course;
import com.androidfreeman.lifesbeengood.repository.CourseRepository;
import com.androidfreeman.lifesbeengood.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/courses")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class CourseController {

    private final CourseRepository courseRepository;
    private final EventService eventService;

    @GetMapping
    @Cacheable("courses")
    public ApiResponse<List<Course>> listCourses() {
        return ApiResponse.success(courseRepository.findAll());
    }

    @PostMapping
    @CacheEvict(value = "courses", allEntries = true)
    public ApiResponse<Course> insertCourse(@RequestBody Course course) {
        if (course.getId() == null || course.getId().isEmpty()) {
            course.setId(UUID.randomUUID().toString());
        }
        Course saved = courseRepository.save(course);
        eventService.emitModulesChanged("courses");
        return ApiResponse.success(saved);
    }
}