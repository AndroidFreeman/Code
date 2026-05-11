package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CourseRepository extends JpaRepository<Course, String> {
}
