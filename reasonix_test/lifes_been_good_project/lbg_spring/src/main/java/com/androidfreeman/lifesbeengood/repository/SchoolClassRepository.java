package com.androidfreeman.lifesbeengood.repository;

import com.androidfreeman.lifesbeengood.model.SchoolClass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SchoolClassRepository extends JpaRepository<SchoolClass, String> {
    boolean existsByClassName(String className);
}
