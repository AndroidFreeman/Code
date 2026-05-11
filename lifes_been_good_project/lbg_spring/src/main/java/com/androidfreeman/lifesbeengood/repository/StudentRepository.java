package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface StudentRepository extends JpaRepository<Student, String> {
    Optional<Student> findByFullNameAndStudentNo(String fullName, String studentNo);
    Optional<Student> findByStudentNo(String studentNo);
    List<Student> findByClassCode(String classCode);
}
